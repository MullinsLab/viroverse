use warnings;
use utf8;
use 5.018;

package ViroDB::ResultSet::Cohort;
use base 'ViroDB::ResultSet';

=head1 METHODS

=head2 list_all

Returns a hashref where the keys are cohort names and the values are hashrefs
with the keys C<cohort_id>, C<name>, and C<show_name>.  C<show_name> is the
cohort name suffixed with the number of subjects in it in parentheses.

This method supports all the callsites which previously made use of
C<Viroverse::patient::list_cohorts()>.

=cut

sub list_all {
    my $self = shift;
    my $me   = $self->current_source_alias;
    return {
        map {;
            $_->name => {
                cohort_id => $_->id,
                name      => $_->name,
                show_name => sprintf("%s (%d)", $_->name, $_->get_column("count")),
            }
        }
        $self->search(undef, { join => "patient_cohorts" })
             ->columns(["$me.cohort_id", "$me.name", { count => \['count(distinct patient_cohorts.patient_id)'] }])
             ->group_by(["$me.cohort_id", "$me.name"])
             ->all
    };
}

1;
