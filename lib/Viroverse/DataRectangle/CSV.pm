use 5.018;
use utf8;
use warnings;
use strict;

package Viroverse::DataRectangle::CSV;
use Moo;
use Text::CSV;
use Types::Standard -types;
use namespace::clean;

=head1 NAME

Viroverse::DataRectangle::CSV - Read a tabular CSV file

=head1 DESCRIPTION

A L<Viroverse::DataRectangle> representation of a CSV file. The first line of
the file will be treated as a header row of column names.

L<Viroverse::DataRectangle::Any> will select this implementation for files with
the extension C<csv>.

=head1 ATTRIBUTES

See L<Viroverse::DataRectangle/ATTRIBUTES> for the complete interface.

=head2 file

The path to a UTF-8 encoded CSV file.

=head1 CAVEATS

Objects of this class may open a filehandle to L</file> and not explicitly close
it.

=cut

with 'Viroverse::DataRectangle';

sub extensions { return ('csv') }

has _fh => (
    is      => 'lazy',
    isa     => FileHandle,
    builder => sub { shift->file->openr_utf8 },
);

has _csv => (
    is      => 'ro',
    isa     => InstanceOf['Text::CSV'],
    default => sub { Text::CSV->new({ binary => 1}) }
);

sub _build_header {
    my $self = shift;
    my $fh = $self->_fh;
    my $csv = $self->_csv;
    return $csv->getline($fh);
}

sub _build_rows {
    my $self = shift;
    my $fh = $self->_fh;
    my $csv = $self->_csv;
    $csv->column_names(@{$self->header});
    my @out;
    while (my $row = $csv->getline_hr($fh)) {
        push @out, $row;
    }
    die "Text::CSV error: " . $csv->error_diag if !$csv->eof or 0+$csv->error_diag;
    close $fh or die "Couldn't close file!";
    return \@out;
}

1;
