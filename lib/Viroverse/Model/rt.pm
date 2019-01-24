package Viroverse::Model::rt;
use Moo;
BEGIN { extends 'Viroverse::CDBI' }

with 'Viroverse::Model::enumerable';

__PACKAGE__->table('viroserve.RT_product');
__PACKAGE__->sequence('viroserve.rt_product_rt_product_id_seq');
__PACKAGE__->columns(All =>
   qw[
        rt_product_id
        extraction_id
        scientist_id
        enzyme_id
        protocol_id
        rna_to_cdna_ratio
        date_completed
        date_entered
        notes
        vv_uid
      ] 
);

__PACKAGE__->has_a(extraction_id => 'Viroverse::Model::extraction');
__PACKAGE__->has_a(scientist_id => 'Viroverse::Model::scientist');
__PACKAGE__->has_a(enzyme_id => 'Viroverse::Model::enzyme');
__PACKAGE__->has_many(pcr_template_id => 'Viroverse::Model::pcr_template');
__PACKAGE__->has_many(primers => ['Viroverse::Model::rt_primer', 'primer_id']);

__PACKAGE__->has_many(copy_numbers => 'Viroverse::Model::copy_number', {order_by => 'date_created DESC'});

sub to_string {
    my $self = shift;

    return join (' ',
        $self->date_completed.'-cDNA',
        '('.(join ',',map {$_->name} $self->primers).')',
        $self->input_product->to_string);
}

sub input_product { $_[0]->extraction_id };
with 'Viroverse::Model::Role::MolecularProduct';

# While relying on the default na_type method from the MolecularProduct role
# would work, defining this here saves a recursive call since an RT product
# should only ever be from an RNA extraction.
sub preferred_sequencing_na_type { "RNA"; }

sub sample_id {
    my $self = shift;

    return $self->extraction_id->sample_id;
}

sub TO_JSON {
    my $self = shift;
    return {
        id=> $self->give_id,
        name=> $self->to_string,
        completed=> $self->date_completed,
        scientist_name=> $self->scientist_id->name,
        sample_name => $self->sample_id ? $self->sample_id->to_string : ''
    };

}

1;
