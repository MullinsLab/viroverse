use strict;
use warnings;
use utf8;
use 5.018;

package ViroDB::ResultSet::Rack;
use base 'ViroDB::ResultSet';

sub in_order {
    my $self = shift;
    return $self->search({}, { order_by => 'order_key' });
}

1;
