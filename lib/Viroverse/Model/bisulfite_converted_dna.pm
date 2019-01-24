use strict;
use warnings;

package Viroverse::Model::bisulfite_converted_dna;
use Moo;
use ViroDB;
BEGIN { extends 'Viroverse::CDBI' };

__PACKAGE__->table('viroserve.bisulfite_converted_dna');
__PACKAGE__->sequence('viroserve.bisulfite_converted_dna_bisulfite_converted_dna_id_seq');

__PACKAGE__->columns(Primary => qw[ bisulfite_converted_dna_id ]);

__PACKAGE__->columns(All => qw[ 
    bisulfite_converted_dna_id 
    extraction_id
    rt_product_id
    sample_id
    scientist_id
    date_entered
    date_completed
    protocol_id
    note
]);

__PACKAGE__->has_a(
    sample_id => 'ViroDB::Result::Sample',
    inflate => sub {
        return ViroDB->instance->resultset('Sample')->find($_[0]);
    },
    deflate => 'id',
);

__PACKAGE__->has_a(protocol_id   => 'Viroverse::Model::protocol');
__PACKAGE__->has_a(extraction_id => 'Viroverse::Model::extraction');
__PACKAGE__->has_a(rt_product_id => 'Viroverse::Model::rt');
__PACKAGE__->has_a(scientist_id  => 'Viroverse::Model::scientist');
__PACKAGE__->has_many(copy_numbers => 'Viroverse::Model::copy_number', {order_by => 'date_created DESC'});

sub input_product {
    my $self = shift;
    return $self->sample_id || $self->extraction_id || $self->rt_product_id;
}
with 'Viroverse::Model::Role::MolecularProduct';

sub to_string {
    my $self = shift;
    return "Bisulfite conversion on " . $self->date_completed
         . " of " . $self->input_product->to_string;
}

sub TO_JSON {
    my $self = shift;
    return {
        id             => $self->give_id,
        name           => $self->to_string,
        completed      => $self->date_completed,
        scientist_name => $self->scientist_id->name,
        sample_name    => $self->input_sample->to_string,
    }
}

1;
