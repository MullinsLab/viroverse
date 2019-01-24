use strict;
use warnings;
use utf8;
use 5.010;

package Mullins::Storage;
use Moo::Role;
use namespace::clean;

requires 'put_path';
requires 'get_path';

=head1 NAME

Mullins::Storage

=head1 DESCRIPTION

A common interface role for file storage backends that code needing such
storage should rely upon instead of backend implementation details.

=head1 REQUIRES

=head2 put_path

Takes a local filesystem path to store.  Any object that stringifies to a
filesystem path is also acceptable, such as L<Path::Tiny> objects.

Returns an opaque storage token string on success and throws an error on
failure.  The storage token may be the actual storage path or a proxy like the
digest of the data.  Regardless, the token should be able to be passed to
L</get_path> to retrieve the data.

=head2 get_path

Takes a storage token returned by a previous L</put_path> call.

Returns a L<Path::Tiny> object pointing to a local filesystem path for the
data.

=cut

1;
