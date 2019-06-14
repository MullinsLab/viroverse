use strict;
use warnings;
use utf8;

package Viroverse::ISLAWorksheet;
use Moo;
use Types::Standard qw< :types >;
use Viroverse::Logger qw< :log >;

=head1 NAME

Viroverse::ISLAWorksheet - convert between a Viroverse::Result::Sample and an
Excel spreadsheet for ISLA data

=head1 ATTRIBUTES

=head2 model

The Viroverse::Model::sample instance that this spreadsheet represents

=head1 METHODS

=head2 make_xlsx

Generates an Excel spreadsheet (in xlsx format) that can be filled out with
added data for the sample. Returns a FileHandle that has been seeked to the
beginning.

=cut

has model => (
    is       => 'ro',
    isa      => Object,
    required => 1,
);

sub make_xlsx {
    my ($self, $url) = @_;

    my $buffer = IO::String->new;
    my $xls = Excel::Writer::XLSX->new($buffer);
    my $sheet = $xls->add_worksheet();


    # Hide the metadata control column
    $sheet->set_column(0, 0, undef, undef, 1);

    # Set the visible columns' widths to reasonable sizes
    $sheet->set_column(1, 1, 26);
    $sheet->set_column(2, 2, 10);
    $sheet->set_column(3, 3, 8);
    $sheet->set_column(4, 4, 3);

    # Enable data protection
    $sheet->protect();

    # Table header format
    my $header = $xls->add_format(
        locked      => 1,
        bg_color    => '#FFCCCC',
        bold        => 1,
        color       => '#000055',
    );

    # Input data label format
    my $label = $xls->add_format(
        locked      => 1,
        bold        => 1,
        color       => '#003333',
    );

    # Locked data cell format
    my $locked = $xls->add_format(
        locked      => 1,
        bold        => 1,
        color       => '#777755',
    );

    my $locked_date = $xls->add_format();
    $locked_date->copy($locked);
    $locked_date->set_format_properties(
        num_format  => 'm/d/yyyy'
    );

    # Locked data cell that carries a URL
    my $locked_url = $xls->add_format();
    $locked_url->copy($xls->get_default_url_format());
    $locked_url->set_format_properties(
        locked      => 1,
        bold        => 0,
        bg_color    => '#EEEEEE',
    );

    # Entry data cell format
    my $unlocked = $xls->add_format(
        locked      => 0,
        bold        => 0,
        color       => 'black',
    );

    my $unlocked_date = $xls->add_format();
    $unlocked_date->copy($unlocked);
    $unlocked_date->set_format_properties(
        num_format  => 'm/d/yyyy'
    );

    # Positive PCR well
    my $pcr_positive = $xls->add_format(
        locked      => 0,
        align       => 'center',
        bg_color    => '#FFFF7F',
        bold        => 1,
        color       => 'black',
    );
    # Negative PCR well
    my $pcr_negative = $xls->add_format(
        locked      => 0,
        align       => 'center',
        bg_color    => '#CCCCCC',
        bold        => 1,
        color       => 'black',
    );
    # PCR well with invalid data
    my $pcr_error = $xls->add_format(
        locked      => 0,
        bg_color    => '#990000',
        bold        => 1,
        color       => 'white',
    );


    my $sample = $self->model;

    # Current write index
    my $row = 0;

    # Output the metadata table header
    $sheet->write($row, 0, 'start_metadata', $header);
    $sheet->write($row, 1, 'Name',           $header);
    $sheet->write($row, 2, 'Value',          $header);
    ++$row;

    # Function to add a metadata row
    my $add_row = sub {
        my ($key, $name, $value, $value_format) = @_;

        $sheet->write($row, 0, $key,    $label);
        $sheet->write($row, 1, $name,   $label);
        if (ref $value eq 'DateTime') {
            $sheet->write_date_time(
                $row, 2,
                $value->strftime('%Y-%m-%dT'),
                $value_format);
        } else {
            $sheet->write(
                $row, 2,
                $value,
                $value_format);
        }
        ++$row;
    };

    # If we were given a sample URL, associate it with the sample_id row
    $sheet->write_url($row, 2, $url) if $url;
    $add_row->('vv_sample_id',
        'Viroverse sample ID',
        $sample->id,
        $url ? $locked_url : $locked);

    # Write the read-only data about the sample
    $add_row->(undef, 'Patient',         $sample->patient->name,     $locked);
    $add_row->(undef, 'Tissue Type',     $sample->tissue_type->name, $locked);
    $add_row->(undef, 'Collection date', $sample->date,              $locked_date)
        if $sample->date;

    $add_row->();

    # Output our worksheet's metadata
    $add_row->('extraction_date',          'DNA extraction date',
        undef, $unlocked_date);
    $add_row->('extraction_cells',         'Cells used (10⁶)',
        undef, $unlocked);
    $add_row->('extraction_concentration', 'Extraction concentration (ng/µL)',
        undef, $unlocked);
    $add_row->('eluted_extraction_volume', 'Eluted volume of extraction (µL)',
        undef, $unlocked);
    $add_row->('input_pcr_per_replicate',  'Input to PCR per replicate (µL)',
        undef, $unlocked);

    $add_row->();

    for my $round (1..3) {
        $add_row->("pcr_date_round$round", "PCR Round $round Date", undef, $unlocked_date);
    }

    $add_row->();

    $add_row->('notes',           'Notes',            undef, $unlocked);

    $add_row->('end_metadata');

    # Add the PCR well header
    $sheet->write($row, 0, "start_pcr", $header);
    $sheet->write($row, 1, "PCR Well",  $header);
    $sheet->write($row, 2, "Position",  $header);
    $sheet->write($row, 3, "Sample ID", $header);
    $sheet->write($row, 4, "+/-",       $header);
    ++$row;

    # Function to add a PCR well
    my $add_pcr_well = sub {
        my ($well_num, $sample_name, $value) = @_;
        my $well_name = Viroverse::Model::gel_lane->intTo96Well($well_num);

        $sheet->write($row, 0, "pcr_well",   $label);
        $sheet->write($row, 1, $well_num,    $label);
        $sheet->write($row, 2, $well_name,   $label);
        $sheet->write($row, 3, $sample_name, $unlocked);
        $sheet->write($row, 4, $value,       $unlocked);
        ++$row;
    };

    my $first_pcr_row = $row;

    for my $well (1..96) {
        $add_pcr_well->($well, undef, undef);
    }

    my $last_pcr_row = $row - 1;

    $add_row->('end_pcr');

    # Add the PCR result hinting formats
    $sheet->conditional_formatting($first_pcr_row, 4, $last_pcr_row, 5, {
        type         => 'text',
        criteria     => 'begins with',
        value        => '+',
        format       => $pcr_positive,
        stop_if_true => 1,
    });
    $sheet->conditional_formatting($first_pcr_row, 4, $last_pcr_row, 5, {
        type         => 'text',
        criteria     => 'begins with',
        value        => '-',
        format       => $pcr_negative,
        stop_if_true => 1,
    });
    $sheet->conditional_formatting($first_pcr_row, 4, $last_pcr_row, 5, {
        type         => 'no_blanks',
        format       => $pcr_error,
        stop_if_true => 1,
    });

    $xls->close() or die "Error saving Excel file: $@";

    $buffer->setpos(0);
    return $buffer;
}

1;
