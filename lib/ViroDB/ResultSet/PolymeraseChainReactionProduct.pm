use strict;
use warnings;
use utf8;
use 5.018;

package ViroDB::ResultSet::PolymeraseChainReactionProduct;
use base 'ViroDB::ResultSet';

sub positive {
    my $self = shift;
    $self->search(
        { 'gel_lanes.pos_result' => 1 },
        { join => 'gel_lanes', distinct => 1 }
    );
}

1;
