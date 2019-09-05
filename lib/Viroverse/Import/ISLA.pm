use strict;
use warnings;
use utf8;
use 5.018;

package Viroverse::Import::ISLA;
use Moo;
use List::Util qw< any all >;
use Viroverse::Logger qw< :log :dlog >;
use Types::Standard -types;
use Viroverse::Types -types;
use Types::Common::String qw< SimpleStr NonEmptySimpleStr >;
use Types::Common::Numeric qw< :types >;
use ViroDB;
use Viroverse::CachingFinder;
use namespace::clean;

with 'Viroverse::Import',
     'Viroverse::Import::HasCreatingScientist';

=head1 DESCRIPTION

Creates the required records for ISLA PCR from a single sample, including
positivity of any final round products.

=cut

has sample => (
    is       => 'ro',
    isa      => ViroDBRecord["Sample"],
    coerce   => 1,
    required => 1,
);

has extraction_date => (
    is       => 'ro',
    isa      => YMD,
    coerce   => 1,
    required => 0,
);

has extraction_cells_used => (
    is       => 'ro',
    isa      => PositiveNum,
    required => 0,
);

has extraction_concentration => (
    is       => 'ro',
    isa      => PositiveNum,
    required => 0,
);

has extraction_eluted_volume => (
    is       => 'ro',
    isa      => PositiveNum,
    required => 0,
);

has extraction => (
    is       => 'rwp',
    isa      => ViroDBRecord[Extraction],
    coerce   => 0,
    init_arg => undef,
);

has pcr_input_dna_volume => (
    is       => 'ro',
    isa      => PositiveNum,
    required => 0,
);

has pcr_round_1_date => (
    is       => 'ro',
    isa      => YMD,
    coerce   => 1,
    required => 1,
);

has pcr_round_2_date => (
    is       => 'ro',
    isa      => YMD,
    coerce   => 1,
    required => 1,
);

has pcr_round_3_date => (
    is       => 'ro',
    isa      => YMD,
    coerce   => 1,
    required => 1,
);

has gel => (
    is => 'lazy',
    isa =>

has '+key_map' => (
    isa => Dict[
        pcr_nickname   => NonEmptySimpleStr,
        pos_neg_result => NonEmptySimpleStr,
    ],
);

sub BUILD {
    my ($self, $args) = @_;
    my @extraction_keys = qw[ extraction_date extraction_eluted_volume
                              extraction_cells_used extraction_concentration ];
    if (  any { defined $args->{$_} } @extraction_keys &&
        ! all { defined $args->{$_} } @extraction_keys) {
        die "All extraction fields must be provided if creating an extraction";
    }
}

sub process_row {
    my ($self, $row) = @_;
    state $db = ViroDB->instance;
    my $units = $db->resultset("Unit");

    # Only one extraction should be created. We do it here instead of with a
    # 'lazy' attribute and _build_extraction to ensure we don't create bogus
    # records before opening the transaction where rows will be processed.
    # If this turns out to be needed in other importers, this should be
    # refactored into a second hook for the Import role, like
    # 'before_processing_rows' or 'do_at_start' or something.
    if ($self->extraction_date && ! $self->extraction) {
        my $extraction = $self->sample->extractions->create({
            scientist          => $self->creating_scientist->id,
            amount             => $self->extraction_cells_used,
            unit               => $units->find({ name => "10^6 cells" }),
            eluted_vol         => $self->extraction_eluted_volume,
            eluted_vol_unit    => $units->find({ name => "ul" }),
            concentration      => $self->extraction_concentration,
            conenctration_unit => $units->find({ name => "ng/ul" }),
        });
        $extraction->discard_changes;
        $self->_set_extraction($extraction);
    }

    my $template = $self->extraction || $self->sample;

    # Linear amplification

    # Binding and extension

    # PCR 1

    # PCR 2

    # PCR 3
}

1;
