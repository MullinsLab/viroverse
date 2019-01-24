use strict;
use warnings;
use utf8;

package Viroverse::AlignmentVisualization;
use Moo;
use Types::Standard -types;

# This component currently assumes that we're interested in alignments to HXB2,
# as does pretty much the rest of Viroverse. That assumption is built in all
# over the place.  If we wanted to make this component more generic, we would
# likely want to change the interface to take an alignment instead of a
# sequence.
has 'sequence' => (
    is       => 'ro',
    isa      => InstanceOf['Viroverse::Model::sequence::dna'],
    required => 1,
);

# Reference regions are drawn as colored lines below the reference axis.
# If none are provided, the reference annotation area will be blank, but
# image height will not be adjusted.
has 'reference_regions' => (
    is       => 'ro',
    isa      => ArrayRef[InstanceOf['ViroDB::Result::GenomeRegion']],
    default  => sub { [] },
);

# 9719 is the length in nt of our HXB2 reference sequence. If we stop assuming
# a reference, this value should be pulled from the alignment itself.
has 'reference_length' => (
    is => 'ro',
    isa => Int,
    default => sub { 9719 },
);

# This is used as the total width in pixels of the SVG image; the reference
# axis will be shorter.
has 'image_width' => (
    is      => 'ro',
    isa     => Int,
    default => sub { 740 },
);

# Pixels of blank space to leave on either side of the reference axis.
has 'x_padding' => (
    is => 'ro',
    isa => Int,
    default => sub { 20 },
);

# The length of the axis, used to scale base pair coordinates, is the total
# width minus the padding on each side. If you were to set this directly to
# some other value, the right padding of the axis wouldn't actually equal
# x_padding.
has 'axis_size' => (
    is      => 'lazy',
    isa     => Int,
    builder => sub { $_[0]->image_width - 2 * $_[0]->x_padding },
);

# Length in fractional pixels of a single base pair of the alignment.
has 'one_base' => (
    is      => 'lazy',
    isa     => Num,
    builder => sub { $_[0]->axis_size / $_[0]->reference_length },
);

# Dictionaries holding the amplification primers for the given sequence, plus
# some additional properties to set how triangles and labels are drawn in the
# diagram. One could pass an empty array to this parameter to prevent primers
# from being drawn. (As with reference regions, image height would not be
# adjusted.)
has 'primer_positions' => (
    is => 'lazy',
    isa => ArrayRef[HashRef],
    builder => 1,
);

sub _build_primer_positions {
    my $self = shift;
    return [] unless $self->sequence->input_product && $self->sequence->input_product->isa("Viroverse::Model::pcr");
    my @out;

    # We tweak how primer labels are displayed for "short" amplicons
    # (ones that use up relatively few pixels of paint) to avoid primer
    # name labels overlapping each other. Current threshhold is 100 pixels.
    # This could be parameterized on the width of the image, font size, etc.
    my @base_range = $self->sequence->hxb2_coverage;
    my $pixel_size = $self->one_base * ($base_range[1] - $base_range[0]);
    my $short_amplicon = $pixel_size < 100;

    for my $pair (@{$self->sequence->input_product->primers_with_proper_positions}) {
        # each $pair is a hashref with keys 'primer' and 'position'; destructure
        # those fields for convenience below
        my $primer = $pair->{primer};
        my $position = $pair->{position};

        # Set drawing and labeling parameters for each (primer, position)
        # The anchor parameter sets the text-anchor attribute for the label
        # elements. Labels go "outwards" for small amplicons, and "inwards"
        # for the rest. "text_twiddle" adjusts positioning to keep labels
        # nearer to their corresponding marks on the alignment.
        if ($primer->orientation eq 'F') {
            $pair->{flip} = 1;
            $pair->{x_pos} = $position->hxb2_end;

            if ($short_amplicon) {
                $pair->{anchor} = 'end';
            } else {
                $pair->{anchor} = 'start';
                $pair->{text_twiddle} = -8;
            }
        } else {
            $pair->{flip} = -1;
            $pair->{x_pos} = $position->hxb2_start;

            if ($short_amplicon) {
                $pair->{anchor} = 'start';
            } else {
                $pair->{anchor} = 'end';
                $pair->{text_twiddle} = 8;
            }
        }
        push @out, $pair;
    }

    return \@out;
}

1;
