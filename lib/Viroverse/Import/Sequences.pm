use strict;
use warnings;
use utf8;
use 5.018;

package Viroverse::Import::Sequences;
use Moo;
use Types::Standard -types;
use Viroverse::Logger qw< :log :dlog >;
use ViroDB;
use Viroverse::CachingFinder;
use Viroverse::Types -types;
use Types::Common::String qw< SimpleStr NonEmptySimpleStr >;
use namespace::clean;

with 'Viroverse::Import',
     'Viroverse::Import::HasCreatingScientist',
     'Viroverse::Import::CanFindPatientSample';

=head1 DESCRIPTION

This importer is for loading sequences from outside sources into Viroverse to
be associated with samples. No attempt will be made to add molecular workflow
steps; sequences where all workflow steps need to be documented should use the
normal sequence input workflow. The import works as follows:

=over

=item *

The sample is looked up based on the given criteria (cohort, subject, date,
tissue type, sample name, and additive). If no such sample exists, or more than
one is found, the job will fail. (This importer will not create subjects,
visits, or samples.)

=item *

If the sample has a sequence with the same name, no sequence is added or
modified and a warning is logged. Revisions of sequences that are already in
Viroverse should be performed using the sequence revision importer.

=item *

Otherwise, it inserts a new sequence.

=back

=cut

has cohort => (
    is => 'ro',
    isa => ViroDBRecord["Cohort"],
    coerce => 1,
    required => 1,
);

has sequence_type => (
    is => 'ro',
    isa => ViroDBRecord["SequenceType"],
    coerce => 1,
    required => 1,
);

has '+key_map' => (
    isa => Dict[
        external_patient_id => NonEmptySimpleStr,
        visit_date          => NonEmptySimpleStr,
        tissue_type         => NonEmptySimpleStr,
        additive            => Optional[SimpleStr],
        sample_name         => Optional[SimpleStr],
        sequence_name       => NonEmptySimpleStr,
        sequence            => NonEmptySimpleStr,
        na_type             => NonEmptySimpleStr,
        scientist_name      => Optional[SimpleStr],
    ],
);

has _scientists => (
    is      => 'ro',
    isa     => InstanceOf["Viroverse::CachingFinder"],
    default => sub { Viroverse::CachingFinder->new(
        resultset => ViroDB->instance->resultset("Scientist"),
        field     => "name",
    )},
);

sub suggested_column_for_key_pattern {
    my ($package, $key) = @_;
    return {
        sample_name         => qr/sample_name|sample/i,
        sequence_name       => qr/sequence_name|name/i,
        sequence            => qr/sequence(?!.*?name)/i,
        scientist_name      => qr/scientist/i,
        external_patient_id => qr/patient|subject|participant/i,
        visit_date          => qr/date/i,
        additive            => qr/additive|modifier/i,
        tissue_type         => qr/tissue|material(?! modifier)/i,
    }->{$key};
}

sub process_row {
    my ($self, $row) = @_;
    state $db = ViroDB->instance;

    my ($patient, $sample) = $self->find_patient_sample(
        $self->cohort,
        $row->{external_patient_id},
        {
            date        => $row->{visit_date},
            name        => $row->{sample_name} || undef,
            tissue_type => $row->{tissue_type},
            additive    => $row->{additive} || undef,
        }
    );

    # If this row isn't labeled with a scientist, fall back to
    # the job's scientist. Otherwise, look them up by name.
    my $scientist = (not $row->{scientist_name})
        ? $self->creating_scientist
        : $self->_scientists->find($row->{scientist_name});

    my $existing_seqs = $sample->search_related("na_sequences", {
        sequence_type_id => $self->sequence_type->id,
        name             => $row->{sequence_name},
    }, {
        join => [ "latest_revision", ],
    })->count;

    if ($existing_seqs) {
        log_warn {[ "A sequence named %s is already present for sample %s",
                     $row->{sequence_name},
                     $sample->id ]};
        $self->track("Sequence already exists");
    } else {
        my $seq = $db->resultset("NucleicAcidSequence")->create({
            name         => $row->{sequence_name},
            na_sequence_revision => 1,
            sequence     => $row->{sequence},
            scientist_id => $scientist->id,
            sample_id    => $sample->id,
            na_type      => $row->{na_type},
            type         => $self->sequence_type,
        });
        log_info{[ "Inserted new sequence %s on sample %s", $seq->idrev, $sample->id ]};
        $self->track("Inserted new sequence");
    }
}

1;
