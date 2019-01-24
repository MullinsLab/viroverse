use strict;
use warnings;

package ViroDB::ResultSet::LegacyProtocol;
use base 'ViroDB::ResultSet';

sub sequencing {
    my $self = shift;
    return $self->search(
        { 'protocol_type.name' => 'sequencing' },
        { join => 'protocol_type' }
    );
}

1;
