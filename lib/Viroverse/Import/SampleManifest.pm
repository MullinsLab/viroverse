use strict;
use warnings;
use utf8;
use 5.018;

package Viroverse::Import::SampleManifest;
use Moo;
use Viroverse::Logger qw< :log :dlog >;
use Types::Standard -types;
use Viroverse::Types -types;
use Types::Common::String qw< SimpleStr NonEmptySimpleStr >;
use Types::DateTime -all;
use DateTime::Format::Strptime;
use ViroDB;
use namespace::clean;

with 'Viroverse::Import',
     'Viroverse::Import::HasCreatingScientist',
     'Viroverse::Import::CanPlaceAliquot',
     'Viroverse::Import::CanPrepareSample',
     'Viroverse::Import::CanPreparePatient';

=head1 DESCRIPTION

Loads the details of samples received from an outside shipment, adding
subjects, visits, samples, and aliquots. This importer is B<not idempotent>: if
you run it repeatedly with the same file as input, it will create new aliquots
each time. It will not create duplicate subjects, visits, or samples.

=cut

has unit => (
    is => 'ro',
    isa => ViroDBRecord["Unit"],
    coerce => 1,
    required => 1,
);

has '+key_map' => (
    isa => WithOptionalFreezerLocation[
        external_patient_id => NonEmptySimpleStr,
        visit_date          => NonEmptySimpleStr,
        visit_number        => Optional[SimpleStr],
        sample_name         => Optional[SimpleStr],
        tissue_type         => NonEmptySimpleStr,
        additive            => Optional[SimpleStr],
        amount              => NonEmptySimpleStr,
    ],
);

has received_date => (
    is => 'ro',
    isa => DateTime->plus_coercions(
        Format[DateTime::Format::Strptime->new(pattern => "%Y-%m-%d")]
    ),
    coerce => 1,
    required => 1,
);

sub suggested_column_for_key_pattern {
    my ($package, $key) = @_;
    return {
        external_patient_id => qr/patient|subject|participant/i,
        visit_date          => qr/date/i,
        additive            => qr/additive|modifier/i,
        tissue_type         => qr/tissue|material(?! modifier)/i,
        amount              => qr/amount|vol/i,
    }->{$key};
}

sub process_row {
    my ($self, $row) = @_;
    state $db = ViroDB->instance;

=over

=item *

The subject is looked up by alias within the cohort. If no such subject exists,
a new subject record is created and given a primary ID in that cohort.

=cut

    my $patient = $self->find_or_create_patient( $row->{external_patient_id} );


=item *

A visit for the subject on the date given in the row is looked up, or created
if it does not exist.

=cut

    # visit_number isn't used in the search because visits are unique for a
    # (patient, date). This means a visit number mismatch between the database
    # visit and the file row will be silently ignored. The visit number of
    # the database visit will not be changed.
    my $visit = $patient->search_related('visits',
        { visit_date => $row->{visit_date} }
    )->first;

    if (!$visit) {
        $visit = $patient->add_to_visits({
            visit_date => $row->{visit_date},
            ($row->{visit_number} ? (visit_number => $row->{visit_number}) : ()),
        });
        $self->track("Visit created");
        log_debug {[ "Creating visit for %s" , $row->{visit_date} ]};
    }

    # Empty the columns of our Result object so the date gets normalized
    # by the database before we use it again.
    $visit->discard_changes;

=item *

The visit is checked for an existing sample of the given tissue type, name, and
additive, which is created if it does not exist.

=cut
    my $sample = $self->find_or_build_sample(
        $visit->related_resultset("samples"),
        {
            name        => $row->{sample_name} || undef,
            tissue_type => $row->{tissue_type},
            additive    => $row->{additive} || undef,
        }
    );

    if (!$sample->in_storage) {
        $sample->insert;
        $self->track("Sample created");
        log_debug {[ "Created a(n) %s sample" , $row->{tissue_type} ]};
    }

=item *

An aliquot of the sample with the given amount is created.
=cut
    my $aliquot = $sample->add_to_aliquots({
        vol                => $row->{amount},
        unit               => $self->unit,
        creating_scientist => $self->creating_scientist,
        received_date      => $self->received_date,
    });
    $self->track("Aliquot created");

=item *

If the aliquot has a freezer, rack, and box set, the aliquot is
placed into the next empty position in the indicated box.

=back

=cut

    $self->place_aliquot($row, $aliquot);

    log_info { ["Aliquot created for %s %s %s: %f %s",
                $patient->name,
                $sample->tissue_type->name,
                $visit->visit_date->strftime("%Y-%m-%d"),
                $aliquot->vol,
                $aliquot->unit->name,
               ]};

}

1;
