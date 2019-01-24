use warnings;
use utf8;
use 5.018;

package ViroDB::ResultSet::ChromatType;
use base 'ViroDB::ResultSet';

=head1 METHODS

=head2 find_from_data

Given a B<byte> string of chromat data, returns the matching
L<ViroDB::Result::ChromatType>, or undef if the type is undeterminable.

This relies on the C<ident_string> property of chromat types.

=cut

sub find_from_data {
    my $self = shift;
    my $data = shift or return;
    return $self->find({ ident_string => substr $data, 0, 4 });
}

1;
