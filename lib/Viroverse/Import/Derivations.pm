use strict;
use warnings;
use utf8;
use 5.018;

package Viroverse::Import::Derivations;
use Moo;
use Viroverse::Logger qw< :log :dlog >;
use Types::Standard -types;
use Viroverse::Types -types;
use Types::Common::String qw< SimpleStr NonEmptySimpleStr >;
use ViroDB;
use Viroverse::CachingFinder;
use namespace::clean;

with 'Viroverse::Import',
     'Viroverse::Import::HasCreatingScientist',
     'Viroverse::Import::CanFindPatientSample',
     'Viroverse::Import::CanPlaceAliquot',
     'Viroverse::Import::CanPrepareSample';

=head1 DESCRIPTION

Loads the details of derivations performed on existing samples, and the
resulting outputs. It will not create patients, visits, or the requested input
samples. It I<will not> create output samples based on the defaults for the
derivation type.

=cut

__PACKAGE__->metadata->set_primary_noun("sample");

has cohort => (
    is => 'ro',
    isa => ViroDBRecord["Cohort"],
    coerce => 1,
    required => 1,
);

has unit => (
    is => 'ro',
    isa => ViroDBRecord["Unit"],
    coerce => 1,
    required => 1,
);

has _scientists => (
    is      => 'ro',
    isa     => InstanceOf["Viroverse::CachingFinder"],
    default => sub { Viroverse::CachingFinder->new(
        resultset => ViroDB->instance->resultset("Scientist"),
        field     => "name",
    )},
);

has _protocols => (
    is      => 'ro',
    isa     => InstanceOf["Viroverse::CachingFinder"],
    default => sub { Viroverse::CachingFinder->new(
        resultset => ViroDB->instance->resultset("DerivationProtocol"),
        field     => "name",
    )},
);

has '+key_map' => (
    isa => WithOptionalFreezerLocation[
        derivation_date              => NonEmptySimpleStr,
        derivation_protocol_name     => NonEmptySimpleStr,
        derivation_scientist_name    => Optional[SimpleStr],
        derivation_uri               => Optional[SimpleStr],
        external_patient_id          => NonEmptySimpleStr,
        input_sample_additive        => Optional[SimpleStr],
        input_sample_name            => Optional[SimpleStr],
        input_sample_tissue_type     => NonEmptySimpleStr,
        visit_date                   => NonEmptySimpleStr,
        output_sample_tissue_type    => Optional[SimpleStr],
        output_sample_name           => Optional[SimpleStr],
        output_sample_amount         => Optional[SimpleStr],
        output_sample_date_collected => Optional[SimpleStr],
    ],
);

sub suggested_column_for_key_pattern {
    my ($package, $key) = @_;
    return {
        external_patient_id      => qr/patient|subject|participant/i,
        visit_date               => qr/date/i,
        input_sample_tissue_type => qr/tissue|material(?! modifier)/i,
        input_sample_additive    => qr/additive|modifier/i,
        derivation_protocol_name => qr/protocol|stim/i,
        derivation_uri           => qr/ur[il]|link/i,
    }->{$key};
}


sub process_row {
    my ($self, $row) = @_;
    state $db = ViroDB->instance;


=pod

The input sample is looked up by cohort, patient alias, date, tissue type,
name, and additive. If a unique input sample is not found, the job fails.

=cut

    my ($patient, $sample) = $self->find_patient_sample(
        $self->cohort,
        $row->{external_patient_id},
        {
            date        => $row->{visit_date},
            name        => $row->{input_sample_name} || undef,
            tissue_type => $row->{input_sample_tissue_type},
            additive    => $row->{input_sample_additive} || undef,
        }
    );

=pod

The sample's child derivations are searched by scientist, protocol,
and completion date. If more than one matching derivation is found, the job
fails. If no derivation is found, a new one is created, I<without>
filling in default outputs.

=cut

    my ($derivation, $derivation_outcome) = $self->_find_or_create_derivation($sample, $row);
    $derivation->discard_changes;


=pod

If the row does not specify the tissue type of an output sample, processing for
this row B<stops>, having ensured the existence of the specified derivation.

=cut

    if (!$row->{output_sample_tissue_type}) {
        log_info { ["%s derivation dated %s %s for %s %s “%s”",
                    $derivation->protocol->name,
                    $derivation->date_completed->ymd,
                    $derivation_outcome,
                    $sample->tissue_type->name,
                    $sample->date->ymd,
                    $sample->name,
                   ]};
        return;
    }

=pod

The derivation is checked for an existing output sample of the given tissue
type, name, and additive, which is created if it does not exist.

=cut

    my ($output_sample, $sample_outcome) = $self->_find_or_create_output_sample($derivation, $row);
    $output_sample->discard_changes;

=pod

If the row does not specify an amount for an aliquot of the output sample,
processing for this row B<stops>, having ensured the existence of the specified
output sample.

=cut

    if (!$row->{output_sample_amount}) {
        log_info { ["%s output %s for %s derivation dated %s of %s %s “%s”",
                    $output_sample->tissue_type->name,
                    $sample_outcome,
                    $derivation->protocol->name,
                    $derivation->date_completed->ymd,
                    $sample->tissue_type->name,
                    $sample->date->ymd,
                    $sample->name,
                   ]};
        return;
    }

=pod

If the row I<does> specify an amount, create a new aliquot (unconditionally)
of the output sample, and place it in a freezer if indicated.

=cut

    # Interpreting the "creating scientist" of an aliquot as always being the
    # person responsible for the import job, not the person who performed
    # the derivation
    my $aliquot = $output_sample->add_to_aliquots({
        vol                => $row->{output_sample_amount},
        unit               => $self->unit,
        creating_scientist => $self->creating_scientist,
        received_date      => $row->{output_sample_date_collected} || $row->{derivation_date},
    });
    $self->track("Aliquot created");

    $self->place_aliquot($row, $aliquot);

    log_info { ["Aliquot created for %s output of %s derivation dated %s of %s %s “%s”",
                $output_sample->tissue_type->name,
                $derivation->protocol->name,
                $derivation->date_completed->ymd,
                $sample->tissue_type->name,
                $sample->date->ymd,
                $sample->name,
               ]};

}

sub _find_or_create_derivation {
    my ($self, $sample, $row) = @_;

    my $proto = $self->_protocols->find($row->{derivation_protocol_name});

    # If this row isn't labeled with a scientist, we won't care about
    # the scientist when looking up a prior derivation
    my $scientist = $row->{derivation_scientist_name} &&
        $self->_scientists->find($row->{derivation_scientist_name});

    my $derivations = $sample->child_derivations->search({
        derivation_protocol_id => $proto->id,
        date_completed         => $row->{derivation_date},
        ($scientist             ? ( scientist_id => $scientist->id ) : ()),
        ($row->{derivation_uri} ? ( uri => $row->{derivation_uri} )  : ()),
    });
    die "Too many matching derivations" if $derivations->count > 1;
    my $derivation = $derivations->first;
    my $created_found;

    # When creating a derivation, we'll use the job's scientist if
    # a scientist is not specified for the row
    if (!$derivation) {
        $derivation = $sample->child_derivations->create({
            protocol       => $proto,
            scientist      => $scientist || $self->creating_scientist,
            date_completed => $row->{derivation_date},
            uri            => $row->{derivation_uri},
        });
        $self->track("Derivation created");
        $created_found = "created";
    } else {
        log_debug { "Derivation exists" };
        $created_found = "found";
    }
    return ($derivation, $created_found);
}

sub _find_or_create_output_sample {
    my ($self, $derivation, $row) = @_;
    my $created_found;

    my $output_sample = $self->find_or_build_sample(
        $derivation->related_resultset('output_samples'),
        {
            name           => $row->{output_sample_name} || undef,
            tissue_type    => $row->{output_sample_tissue_type},
            additive       => $row->{output_sample_additive} || undef,
            date_collected => $row->{output_sample_date_collected} || undef,
        },
    );

    if (!$output_sample->in_storage) {
        $output_sample->insert;
        $self->track("Output sample created");
        log_debug {[ "Created a(n) %s sample" , $row->{output_sample_tissue_type} ]};
        $created_found = "created";
    } else {
        log_debug { "Output sample exists" };
        $created_found = "found";
    }
    return ($output_sample, $created_found);
}

1;
