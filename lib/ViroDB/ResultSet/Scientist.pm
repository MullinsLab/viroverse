use strict;
use warnings;
use utf8;
use 5.018;

package ViroDB::ResultSet::Scientist;
use base 'ViroDB::ResultSet';

=head1 METHODS

=head2 active

Constraints current resultset to scientists who do not have the C<retired> role

=cut

sub active {
    my $self = shift;
    my $me = $self->current_source_alias;
    $self->search({ "$me.role" => { '!=' => 'retired' } });
}

1;
