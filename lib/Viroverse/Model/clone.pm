package Viroverse::Model::clone;
use Moo;
BEGIN { extends 'Viroverse::CDBI' }

with 'Viroverse::Model::enumerable';
__PACKAGE__->table('viroserve.clone');
__PACKAGE__->sequence('viroserve.clone_clone_id_seq');
__PACKAGE__->columns(All =>
    qw[
        clone_id
        name
        pcr_product_id
        scientist_id
        date_completed
        vv_uid
        date_added
        ]
);

sub sample_id {
    my $self = shift;

    return $self->pcr_product_id->sample_id;
}

sub input_product { $_[0]->pcr_product_id };
with 'Viroverse::Model::Role::MolecularProduct';

__PACKAGE__->has_a(scientist_id => 'Viroverse::Model::scientist');
__PACKAGE__->has_a(pcr_product_id => 'Viroverse::Model::pcr');


sub to_string {
    my $self = shift;

    my $name; 
    $name .= $self->pcr_product_id ? $self->pcr_product_id->to_string() : 'unknown PCR';

    return $name;
}

1;
