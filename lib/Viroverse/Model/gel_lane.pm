package Viroverse::Model::gel_lane;
use base 'Viroverse::CDBI';
use Carp qw[croak];
use strict;

my %decode = (
    'pos' => 1,
    'neg' => 0,
    'ind' => undef
);

__PACKAGE__->table('viroserve.gel_lane');
__PACKAGE__->sequence('viroserve.gel_lane_gel_lane_id_seq');
__PACKAGE__->columns(All =>
    qw[
        gel_lane_id
        gel_id
        pcr_product_id
        name
        loc_x
        loc_y
        label
        pos_result
        ]
);

__PACKAGE__->has_a(pcr_product_id => 'Viroverse::Model::pcr');
__PACKAGE__->has_a(gel_id => 'Viroverse::Model::gel');

sub product {
    my $self = shift;

    return $self->pcr_product_id || undef;
}

sub hasPositivity {
    my $self = shift;

    if(defined($self->product) || $self->stock_labels->{$self->name()}->{pos} == 1){
        return 1;
    }else{
        return 0;
    }

}

=item %stock_labels
    maps commonly used special_label names keyed to sensible defaults
=cut
sub stock_labels {
    my $pkg = shift;
    return {
        'pos. control' => {pos => 1, default => 1},
        'neg. control'=> {pos => 1, default => 1},
        'empty well' => {pos => 0, default => 0},
        'inhibition pos. control' => { pos => 1, default => 0 },
        'neg. control with hgDNA' => { pos => 0, default => 0 },
    };
}

sub pos_decode {
    my ($pkg, $value) = @_;

    return $decode{$value};
}

sub to_string {
    my $self = shift;
    if($self->pcr_product_id()){
        return $self->pcr_product_id->to_string();
    }else{
        return $self->name();
    }
}

sub print_label {
    my $self = shift;
    if($self->gel_id->ninety_six_well()){
        return __PACKAGE__->intTo96Well($self->label());
    }
    return $self->label();
}

sub intTo96Well {
    my ($pkg, $int) = @_;
    croak "$int is greater than a 96 well plate" if $int > 96;

    # 1..96 -> 0..95
    my $position = $int - 1;

    # Get the group of 12
    my $alpha_key = int($position/12);

    # Get the position with in the group of 12 as 0..11, then shift to 1..12
    my $numeric = ($position % 12) + 1;

    return sprintf('%c%02d', ord('A') + $alpha_key, $numeric);
}

1;
