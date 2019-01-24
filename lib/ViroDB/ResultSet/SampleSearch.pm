use strict;
use warnings;

package ViroDB::ResultSet::SampleSearch;
use base 'ViroDB::ResultSet';

=head2 search_where

Aliases L<DBIX::Class::ResultSet/search> for the benefit of
L<Viroverse::Controller::enum/find_generic>.

=head2 transform_search

Converts the search hash produced by L<Viroverse::Controller::enum/find_generic>
into something suitable for searching on this model.

Any C<na_type> key is converted to a condition on C<sample_type> using one of
the well-known values C<cells> or C<RNA>.

Any C<date_completed> key is converted to a condition on C<visit_date>.

Returns a list of transformed key-value pairs.

=cut

sub search_where {
    my ($self, $conditions) = @_;
    $self->search($conditions)->all;
}

sub transform_search {
    my $self       = shift;
    my $conditions = { @_ };

    # na_type converts to an equivalent sample_type _or_ a null sample_type
    if (my $na = uc delete $conditions->{na_type}) {
        $conditions->{sample_type} = [
            { '=' => {DNA => "cells", RNA => "RNA"}->{$na} },
            { -is => undef }
        ];
    }

    # find_generic uses date_completed as a generic date field; our date field
    # is visit_date
    if (my $date = delete $conditions->{date_completed}) {
        $conditions->{visit_date} = $date;
    }

    return %$conditions;
}

# primary_column is here as a compatibility shim with CDBI for use in
# find_generic, and probably doesn't interact with anything else. Notably
# it has nothing to do with DBIC's key handling as managed by set_primary_key
# on a result class.
sub primary_column { "sample_id" };

1;
