use strict;
use warnings;
use utf8;
use 5.018;

package Viroverse::Import::SampleNotes;
use Moo;
use Types::Common::String qw< SimpleStr NonEmptySimpleStr NonEmptyStr >;
use Types::Standard -types;
use ViroDB;
use Viroverse::CachingFinder;
use Viroverse::Logger qw< :log :dlog >;
use namespace::clean;

with 'Viroverse::Import',
     'Viroverse::Import::HasCreatingScientist',
     'Viroverse::Import::CanFindPatientSample';

=head1 DESCRIPTION

=encoding UTF-8

This importer adds notes to existing samples.

If a note already exists with the exact same content and creating scientist, it
will not be re-created.

=cut

__PACKAGE__->metadata->set_label("Sample Notes");
__PACKAGE__->metadata->set_primary_noun("sample");

has _cohorts => (
    is      => 'ro',
    isa     => InstanceOf["Viroverse::CachingFinder"],
    default => sub {
        Viroverse::CachingFinder->new(
            resultset => ViroDB->instance->resultset("Cohort"),
            field     => "name",
        )
    },
);

has '+key_map' => (
    isa => Dict[
        # For the sample
        cohort              => NonEmptySimpleStr,
        external_patient_id => NonEmptySimpleStr,
        sample_date         => NonEmptySimpleStr,
        sample_name         => Optional[SimpleStr],
        tissue_type         => NonEmptySimpleStr,
        additive            => Optional[SimpleStr],

        # For the note
        note                => NonEmptyStr,
    ],
);

sub suggested_column_for_key_pattern {
    my ($package, $key) = @_;
    return {
        external_patient_id => qr/patient|subject|participant/i,
        sample_date         => qr/date/i,
        sample_name         => qr/sample_name|sample/i,
        tissue_type         => qr/tissue|material(?! modifier)/i,
        additive            => qr/additive|modifier/i,
        note                => qr/note|comment/i,
    }->{$key};
}

sub process_row {
    my ($self, $row) = @_;
    state $db = ViroDB->instance;

    my $cohort = $self->_cohorts->find( $row->{cohort} );

    my ($patient, $sample) = $self->find_patient_sample(
        $cohort,
        $row->{external_patient_id},
        {
            date        => $row->{sample_date},
            name        => $row->{sample_name},
            tissue_type => $row->{tissue_type},
            additive    => $row->{additive},
        }
    );

    my $sample_description =
        sprintf "%s sample for %s %s on %s%s (#%s)",
            $row->{tissue_type},
            $cohort->name,
            $row->{external_patient_id},
            $row->{sample_date},
            ($row->{sample_name} ? " named “$row->{sample_name}”" : ""),
            $sample->id;

    # Look for this exact existing note.  If found, there's nothing to do.
    # Otherwise, create it.
    my $note = $sample->find_or_new_related("notes", {
        body         => $row->{note},
        scientist_id => $self->creating_scientist->id,
    });

    if ($note->in_storage) {
        log_debug {[ "Found note #%s", $note->id ]};
        $self->track("Note exists");
    } else {
        $note->insert;
        $note->discard_changes;
        log_info {[ "Created note #%s for %s", $note->id, $sample_description ]};
        $self->track("Note created");
    }
}

1;
