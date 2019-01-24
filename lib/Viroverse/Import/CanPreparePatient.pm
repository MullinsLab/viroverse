use strict;
use warnings;
use utf8;
use 5.018;

package Viroverse::Import::CanPreparePatient;
use Moo::Role;
use Viroverse::Logger qw< :log >;
use Viroverse::Types -types;
use namespace::clean;

=head1 NAME

Viroverse::Import::CanPreparePatient - A role for importers to find or create patients in a cohort

=head1 REQUIRES

=head2 track

Required method for tracking when new patients are created by
L</find_or_create_patient>.  This should be provided by L<Viroverse::Import>.

=cut

requires 'track';


=head1 ATTRIBUTES

=head2 cohort

A L<ViroDB::Result::Cohort>, coercible from a numeric id, in which to find or
or create patients.

Required.

=cut

has cohort => (
    is => 'ro',
    isa => ViroDBRecord["Cohort"],
    coerce => 1,
    required => 1,
);


=head1 METHODS

=head2 find_or_create_patient

Given an L<external patient id|ViroDB::Result::PatientAlias/external_patient_id>,
retrieve an existing patient from L</cohort>.  If none exists, create a new
L<ViroDB::Result::Patient> instance and return it.

=cut

sub find_or_create_patient {
    my ($self, $external_patient_id) = @_;

    my $patient = $self->cohort->find_patient_by_alias( $external_patient_id );

    if (not $patient) {
        $patient = $self->cohort->add_to_patients({});
        $patient->add_to_patient_aliases({
            type => "primary",
            cohort              => $self->cohort,
            external_patient_id => $external_patient_id,
        });
        $self->track("Patient created");
        log_debug {[ "Added patient %s %s", $self->cohort->name, $external_patient_id ]};
    }

    return $patient;
}

1;
