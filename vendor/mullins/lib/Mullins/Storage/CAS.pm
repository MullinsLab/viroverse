use strict;
use warnings;
use utf8;
use 5.010;

package Mullins::Storage::CAS;
use Moo;
use Types::Standard qw< :types >;
use Types::Path::Tiny qw< Dir >;
use DataStore::CAS::Simple;
use Path::Tiny;
use namespace::clean;

=head1 NAME

Mullins::Storage::CAS

=head1 SYNOPSIS

    my $storage   = Mullins::Storage::CAS->new(path => "./path/to/store");

=head1 DESCRIPTION

Implements the L<Mullins::Storage> role with an on-disk content-address store
using L<DataStore::CAS::Simple>.

=head1 ATTRIBUTES

=head2 path

The filesystem path where the store is rooted. The path must be to an
existing directory. If the directory is empty, the L<DataStore::CAS::Simple> will
be initialized. If it is not empty and not a CAS, initialization will fail.

=cut

with 'Mullins::Storage';

has path => (
    is       => 'ro',
    isa      => Dir,
    required => 1,
    coerce   => 1,
);

has _store => (
    is       => 'lazy',
    isa      => InstanceOf['DataStore::CAS::Simple'],
    init_arg => undef,
);

sub _build__store {
    my $self = shift;
    return DataStore::CAS::Simple->new(create => 1, path => $self->path);
}

sub get_path {
    my $self   = shift;
    my $digest = shift;
    my $file   = $self->_store->get($digest)
        or return undef;
    return path($file->local_file);
}

sub put_path {
    my $self = shift;
    my $path = shift;
    return $self->_store->put_file("$path");
}

1;
