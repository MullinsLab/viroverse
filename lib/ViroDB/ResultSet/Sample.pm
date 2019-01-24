use strict;
use warnings;

package ViroDB::ResultSet::Sample;
use base 'ViroDB::ResultSet';

use Viroverse::Logger qw< :log :dlog >;

=head1 METHODS

=head2 search_naturally

Takes a hashref of simplified search parameters and returns a new resultset
based on the current one.  See also L</find_naturally>, which is what you
should use most of the time.

Parameters are:

=over

=item name

Sample name

=item tissue_type

Tissue type name

=item additive

Additive name

=back

If not provided they default to C<undef>, which translates to an C<IS NULL>
condition.

In addition, one and B<only one> of the following is required:

=over

=item date

Hierarchical sample date as used in many places, coalesced in order from
L<ViroDB::Result::Sample/date_collected>,
L<ViroDB::Result::Derivation/date_completed>, and
L<ViroDB::Result::Visit/visit_date>.  This is the same date used in our sample
search views.

=item date_collected

Date of sample collection, which is generally only set I<when it is distinct from>
the date of a derivation for a derived sample. (For derivations where the
protocol actually lasts many days.)

=back

=cut

sub search_naturally {
    my ($self, $params, $options) = @_;
    my $me = $self->current_source_alias;

    die "One and only one of date or date_collected must be given"
       unless exists $params->{date}
          xor exists $params->{date_collected};

    return $self->search(
        {
            "$me.name"           => $params->{name},
            # Tissue name lookup can be case insensitive because there's
            # a case-insensitive unique index on the tissue_type.name column.
            -bool                => \['lower(tissue_type.name) = lower(?)', $params->{tissue_type}],
            'additive.name'      => $params->{additive},

            (exists $params->{date}
                ? ('patient_and_date.sample_date' => $params->{date})
                : ()),

            (exists $params->{date_collected}
                ? ("$me.date_collected" => $params->{date_collected})
                : ()),
        },
        {
            join => [
                'tissue_type',
                'additive',
                (exists $params->{date}
                    ? 'patient_and_date'
                    : ())
            ],

            %{ $options || {} },
        }
    );
}

=head2 find_naturally

Takes the same first argument as L</search_naturally> and returns either the
unique sample matching the parameters, or undef if there is no match.  Dies if
more than one sample matches, because we very much don't want to find more than
one sample and if more than one is found we have to deal with it.

=cut

sub find_naturally {
    my ($self, $params) = @_;

    my $results = $self->search_naturally(
        $params,
        {
            # Don't bother fetching more than two rows.  If we have more than
            # one row, we're going to die anyway.
            rows => 2,
        }
    );

    my $first = $results->first;
    Dlog_fatal { "find_naturally yielded too many samples: $_" } [ map { $_->as_hash } $results->rows(undef)->all ]
        if $results->next;
    return $first;
}

=head2 rollup_by_tissue_type

Groups the current resultset by tissue type and appends a column C<count>
giving the number of samples in each group.

Since there's no C<count> slot on L<ViroDB::Result::Sample>, one must call
L<get_column("count")|DBIx::Class::Row/get_column> on a result row to get the
group count.


=cut

sub rollup_by_tissue_type {
    my ($self) = @_;
    my $me = $self->current_source_alias;
    $self->as_subselect_rs
         ->group_by([ "$me.tissue_type_id" ])
         ->columns([ 'tissue_type_id', { 'count' => { 'COUNT' => "$me.sample_id" } } ])
         ->order_by({ -desc => 'count' });
}

1;
