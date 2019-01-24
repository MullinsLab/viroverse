use strict;
use warnings;

package ViroDB::ResultSet::NumericLabResult;
use base 'ViroDB::ResultSet';

sub without_viral_load_and_cell_counts {
    my $self = shift;
    return $self->search(
        {
            # This is ugly and I don't like its tight coupling with the
            # viral_load and cell_count view definitions.  I'm not sure how
            # best to handle it more properly, and this sure is easy.  One
            # better option might be to use a view to contain this logic,
            # moving it closer to the definitions of the other views, but it
            # would be about all the view did.
            #   -trs, 26 June 2017
            'type.name' => {
                -not_like => 'viral load%',
                -not_in   => ['CD4', 'CD4 calc', 'CD8', 'CD8 calc'],
            },
        },
        { join => 'type' }
    );
}

1;
