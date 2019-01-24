use strict;
use warnings;

package ViroDB::SerializableAsJSON;
use base 'DBIx::Class';
use namespace::clean;

=head1 NAME

ViroDB::SerializableAsJSON - Provides a TO_JSON method which dispatches to
as_hash

=head1 SYNOPSIS

    __PACKAGE__->load_components("+ViroDB::SerializableAsJSON");

=head1 DESCRIPTION

Provides a result method L<TO_JSON> for use by L<JSON>, L<JSON::MaybeXS>,
L<Cpanel::JSON::XS>, etc which simply calls C<as_hash>.  If C<as_hash> is not
overriden in the result class, then a default implementation provided by this
component returns a new hashref using L<DBIx::Class::Row/get_columns>.

=cut

sub TO_JSON { $_[0]->as_hash }
sub as_hash {
    return { $_[0]->get_columns };
}

1;
