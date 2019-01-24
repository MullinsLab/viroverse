use strict;
use warnings;

package ViroDB::ResultSet::CohortPatientSummary;
use base 'ViroDB::ResultSet';

sub distinct_by_patient {
    my $self = shift;
    my $me   = $self->current_source_alias;
    $self->search({}, {
        columns => [qw[
            patient_id
            estimated_date_infected
            art_initiation_date
            first_visit
            latest_visit
            pbmc_count
            plasma_count
            leuka_count
            other_count
        ]],
        '+select' => [ "viroserve.patient_name($me.patient_id)", 'viral_load_values::jsonb' ],
        '+as'     => [ 'name', 'viral_load_values' ],
        distinct  => 1,
        order_by  => "viroserve.patient_name($me.patient_id)",
    });
}

1;
