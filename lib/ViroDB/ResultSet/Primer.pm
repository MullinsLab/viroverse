use strict;
use warnings;
use 5.018;
use utf8;

package ViroDB::ResultSet::Primer;
use base 'ViroDB::ResultSet';

sub plausible_for {
    my ($self, $query) = @_;
    my $me    = $self->current_source_alias;
    my $where = qq{
                    regexp_replace(upper($me.name), '[^A-Z0-9]', '', 'g')
        LIKE '%' || regexp_replace(upper(?),        '[^A-Z0-9]', '', 'g') || '%'
    };

    return $self->search(\[ $where, $query ])
        ->order_by(\[ "length(?)::float / length($me.name) desc, $me.name asc", $query ]);
}

1;
