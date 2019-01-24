use strict;
use warnings;
use utf8;
use 5.018;

package Viroverse::Import::NumericLabResults;
use Moo;
use Type::Utils -all;
use Types::Standard -types;
use Viroverse::Logger qw< :log :dlog >;
use Viroverse::Types -types;
use namespace::clean;

with 'Viroverse::Import',
     'Viroverse::Import::HasCreatingScientist';

=head1 DESCRIPTION

This importer loads numeric lab results of a single type, for patients in a
single cohort. The cohort and lab result type are set in the prepare step.
For each row, records are updated as follows:

=over

=cut

has lab_result_type => (
    is => 'ro',
    isa => ViroDBRecord["NumericLabResultType"],
    coerce => 1,
    required => 1,
);

has cohort => (
    is => 'ro',
    isa => ViroDBRecord["Cohort"],
    coerce => 1,
    required => 1,
);

has '+key_map' => (
    is => 'ro',
    isa => Dict[
        external_patient_id => Str,
        visit_date          => Str,
        value               => Str,
    ],
);

sub suggested_column_for_key_pattern {
    my ($package, $key) = @_;
    return {
        external_patient_id => qr/patient|pid|subject/i,
        visit_date          => qr/visit_date|visit|date/i,
    }->{$key};
}

sub process_row {
    my ($self, $row) = @_;

    unless (defined $row->{value} and length $row->{value}) {
        $self->track("Skipped empty value");
        Dlog_debug { "Skipped row with empty value: $_" } $row;
        return;
    }

=item *

The patient is looked up by alias within the cohort. If a patient alias is not
found, the importer aborts. (This importer will not create patients.)

=cut

    my $patient = $self->cohort->find_patient_by_alias($row->{external_patient_id});

    if (!$patient) {
        die "Couldn't match patient: " . $row->{external_patient_id};
    }

=item *

A visit for the patient on the date given in the row is looked up. A new visit
record is created if no visit for the given date exists.

=cut

    my $visit = $patient->search_related('visits',
        { visit_date => $row->{visit_date} }
    )->first;

    if (!$visit) {
        $visit = $patient->add_to_visits({
            visit_date => $row->{visit_date},
        });
        $self->track("Visit created");
        log_debug { ["Creating visit for %s" , $row->{visit_date}] };
    }

    # Empty the columns of our Result object so the date gets normalized
    # by the database before we use it again.
    $visit->discard_changes;

=item *

The visit is checked for an existing lab result of the given type.

=over

=cut
    my $existing_lab_result = $self->lab_result_type->search_related('results',
        { visit_id => $visit->id, }
    )->first;

=item *

If a lab result already exists, the database value is replaced with the file
value when they differ.

=item *

Otherwise, a new lab result is inserted for the given visit.

=back

=back

=cut

    my $outcome;
    if ($existing_lab_result) {
        log_debug { "Existing value: " . $existing_lab_result->value };
        log_debug { "   Input value: " . $row->{value} };
        if ($existing_lab_result->value != $row->{value}) {
            $existing_lab_result->update({
                value      => $row->{value},
                scientist  => $self->creating_scientist,
                date_added => \[ "now()" ],
            });
            $outcome = "updated";
        } else {
            $outcome = "unchanged";
        }
    } else {
        $existing_lab_result = $self->lab_result_type->add_to_results({
            visit_id     => $visit->id,
            value        => $row->{value},
            scientist_id => $self->creating_scientist->id,
        });
        $outcome = "created";
    }

    $self->track("Lab result $outcome");
    log_info { ["Lab result %s for %s %s: %g",
                $outcome,
                $patient->name,
                $visit->visit_date->strftime("%Y-%m-%d"),
                $existing_lab_result->value,
               ]};
}


1;
