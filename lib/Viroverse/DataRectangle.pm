use 5.018;
use utf8;
use warnings;
use strict;

package Viroverse::DataRectangle;
use Moo::Role;
use Types::Standard -types;
use Types::Common::String qw< SimpleStr NonEmptyStr NonEmptySimpleStr >;
use Types::Path::Tiny qw< File >;
use namespace::clean;

=head1 NAME

Viroverse::DataRectangle - Read rows of columnar data

=head1 DESCRIPTION

The DataRectangle role defines a common interface for the task of reading rows
of input data from files of various formats. L</ATTRIBUTES> below describes the
interface defined by DataRectangle, L</REQUIRES> provides instructions for
implementing a consumer of the role.

=head1 ATTRIBUTES

=head2 file

The path to a file (or a L<Path::Tiny> object) containing the data to be
parsed. Must be provided to constructor.

=head2 file_extension

If the name of L</file> doesn't end in an extension, one most be provided to the
constructor as L</file_extension> (without a period at the beginning).

=head2 header

An arrayref of column/variable names from L</file>

=head2 rows

An arrayref of hashrefs mapping elements of L</header> to values.

=head1 REQUIRES

=head2 extensions

Consumers must implement the L</extensions> class method, which simply returns
a list of file extensions that the class can read data from. This is used by
L<Viroverse::DataRectangle::Any> to choose an implementation based on the file
being read.

=head2 _build_header

A builder for the L</header> attribute. Should read the equivalent of column
headers from L</file> and return them as an array reference.

=head2 _build_rows

A builder for the L</rows> attribute. Should read individual rows or entries
from L</file> and return an arrayref of hashrefs where the keys are elements of
L</header> and the values are strings.

=cut

requires '_build_header';
requires '_build_rows';
requires 'extensions';

has header => (
    is       => 'lazy',
    isa      => ArrayRef[SimpleStr],
    init_arg => undef,
);

has rows => (
    is       => 'lazy',
    isa      => ArrayRef[HashRef[Str]],
    init_arg => undef,
);

has file => (
    is       => 'ro',
    isa      => File,
    required => 1,
    coerce   => 1,
);

has file_extension => (
    is      => 'lazy',
    isa     => NonEmptySimpleStr,
);

sub _build_file_extension {
    my $self = shift;
    return (split /[.]/, $self->file->basename)[-1];
}

sub BUILD {
    my ($self, $args) = @_;
    return if $args->{file_extension};
    die "A file extension must be provided for file $args->{file}"
        unless $args->{file} =~ /\.[^.]+$/;
}

1;
