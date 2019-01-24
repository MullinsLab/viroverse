use 5.018;
use utf8;
use warnings;
use strict;

package Viroverse::DataRectangle::Excel;
use Moo;
use Types::Standard -types;
use Spreadsheet::ParseExcel;
use Spreadsheet::ParseXLSX;
use namespace::clean;

=head1 NAME

Viroverse::DataRectangle::Excel - Read a tabular Microsoft Excel file

=head1 DESCRIPTION

A L<Viroverse::DataRectangle> representation of a Microsoft Excel file.

Data will be extracted from spreadsheets assuming that they are reasonably tidy
and sane to begin with. The first data-containing row of the first worksheet
will be used as the header, and all subsequent rows, up through the last
nonempty row of the worksheet, will be used to extract data columns. If the
provided spreadsheet doesn't meet these assumptions, the resulting data
structure will probably be bonkers.

L<Viroverse::DataRectangle::Any> will select this implementation for files with
the extension C<xls> or C<xlsx>.

=head1 ATTRIBUTES

See L<Viroverse::DataRectangle/ATTRIBUTES> for the complete interface.

=head2 file

The path to a Microsoft Excel spreadsheet file, in either Office 97 (XLS) or
2007 (XLSX) format.

=head2 file_extension

L</file> should end in C<xls> or C<xlsx>. If it doesn't, identify the format to
parse as L</file_extension>.

=cut

sub extensions {
    return qw( xls xlsx );
}

with 'Viroverse::DataRectangle';

has worksheet => (
    is => 'lazy',
    isa => InstanceOf['Spreadsheet::ParseExcel::Worksheet']
);

sub _build_worksheet {
    my $self = shift;
    my $parser;
    if ($self->file_extension eq "xls") {
        $parser = Spreadsheet::ParseExcel->new;
    } else {
        $parser = Spreadsheet::ParseXLSX->new;
    }
    my $spreadsheet = $parser->parse($self->file->openr_utf8);
    die "Couldn't read " . $self->file . " as " . $self->file_extension
        unless $spreadsheet;
    return $spreadsheet->worksheet(0);
}

sub _build_header {
    my $self = shift;
    my ($row_min, $row_max) = $self->worksheet->row_range;
    my ($col_min, $col_max) = $self->worksheet->col_range;

    my @headers;
    for my $col_i ($col_min..$col_max) {
        my $cur = $self->worksheet->get_cell($row_min, $col_i);
        push @headers, (defined $cur ? $cur->value : "");
    }
    return \@headers;
}

sub _build_rows {
    my $self = shift;
    my ($row_min, $row_max) = $self->worksheet->row_range;
    my ($col_min, $col_max) = $self->worksheet->col_range;
    my @headers = @{$self->header};

    my @rows;
    for my $row_i ($row_min+1..$row_max) {
        my %row = ();
        for my $col_i ($col_min..$col_max) {
            my $cell = $self->worksheet->get_cell($row_i, $col_i);
            $row{$headers[$col_i - $col_min]} = (defined $cell ? $cell->value : "");
        }
        push @rows, \%row;
    }
    return \@rows;
}

1;
