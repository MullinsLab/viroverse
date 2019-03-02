package Viroverse::Model::pcr_template;
use strict;
use Carp qw[croak];
use Moo;
use ViroDB;
BEGIN { extends 'Viroverse::CDBI' };

__PACKAGE__->table('viroserve.pcr_template');
__PACKAGE__->sequence('viroserve.pcr_template_pcr_template_id_seq');
__PACKAGE__->columns(All =>
   qw[
        pcr_template_id
        volume
        dil_factor
        unit_id
        scientist_id
        date_completed
        date_entered
        rt_product_id
        extraction_id
        bisulfite_converted_dna_id
        pcr_product_id
        sample_id
      ] 
);

__PACKAGE__->has_a(rt_product_id => 'Viroverse::Model::rt');
__PACKAGE__->has_a(extraction_id => 'Viroverse::Model::extraction');
__PACKAGE__->has_a(pcr_product_id => 'Viroverse::Model::pcr');
__PACKAGE__->has_a(bisulfite_converted_dna_id => 'Viroverse::Model::bisulfite_converted_dna');
__PACKAGE__->has_a(scientist_id => 'Viroverse::Model::scientist');
__PACKAGE__->has_a(unit_id => 'Viroverse::Model::unit');
__PACKAGE__->has_a(
    sample_id => 'ViroDB::Result::Sample',
    inflate => sub {
        return ViroDB->instance->resultset('Sample')->find($_[0]);
    },
    deflate => 'id',
);

sub input_product {
    my $self = shift;
    return $self->rt_product_id || $self->extraction_id || $self->pcr_product_id ||
           $self->sample_id     || $self->bisulfite_converted_dna_id;
}
with 'Viroverse::Model::Role::MolecularProduct';

sub to_string {
    my $self = shift;

    my $parent = $self->input_product;
    my $name;
    $name .= sprintf "%s %s ", $self->volume, $self->unit_id->name if $self->volume;
    $name .= $parent->to_string if $parent;

    $name .= ' diluted to '.$self->dil_factor if ($self->dil_factor and $self->dil_factor != 1);

    return $name;
}

sub volume_with_unit {
    my $self = shift;
    return if not $self->unit_id;
    return $self->unit_id->with_magnitude($self->volume);
}

1;
