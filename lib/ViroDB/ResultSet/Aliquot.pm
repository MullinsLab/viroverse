use strict;
use warnings;
use utf8;
use 5.018;

package ViroDB::ResultSet::Aliquot;
use base 'ViroDB::ResultSet';

=head1 METHODS

=head2 available

Restricts the current resultset to aliquots that are not given out, lost,
or empty

=cut

sub available {
    my $self = shift;
    my $me = $self->current_source_alias;

    return $self->search(
        {
            "$me.possessing_scientist_id" => undef,
            "$me.orphaned"                => undef,
            "$me.vol"                     => [ { ">" => 0 }, undef ],
        },
    );
}

=head2 rollup_by_quantity

Groups the current resultset by unit and volume and appends a column
C<count> giving the number of aliquots in each group.

Since there's no C<count> slot on L<ViroDB::Result::Aliquot>, one must call
L<get_column("count")|DBIx::Class::Row/get_column> on a result row to get
the group count.

=cut

sub rollup_by_quantity {
    my $self = shift;
    my $me = $self->current_source_alias;
    $self->as_subselect_rs
         ->order_by([ "$me.unit_id", "$me.vol" ])
         ->group_by([ "$me.vol", "$me.unit_id" ])
         ->columns([ 'vol', 'unit_id', { 'count' => { 'COUNT' => "$me.aliquot_id" } } ]);
}


1;
