use strict;
use warnings;
use utf8;
use 5.018;

package Viroverse::Storage;

=head1 NAME

Viroverse::Storage

=head1 DESCRIPTION

Provides app-wide access to a singleton L<Mullins::Storage> instance.

=head1 METHODS

=head2 instance

Return an object with the L<Mullins::Storage> interface. The caller may assume
that whatever is returned will correctly map any storage keys it has to the
correct stored data.

=cut

use Mullins::Storage::CAS;
use Viroverse::Config;

sub instance {
    my $self = shift;
    state $cas = Mullins::Storage::CAS->new(path => Viroverse::Config->conf->{storage});
    return $cas;
}

1;
