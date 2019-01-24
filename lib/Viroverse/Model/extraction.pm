package Viroverse::Model::extraction;
use Moo;
BEGIN { extends 'Viroverse::CDBI' }

use Viroverse::Model::scientist;
use Viroverse::session;
use Viroverse::db;
use ViroDB;
use Safe::Isa qw< $_call_if_object >;

with 'Viroverse::Model::enumerable';

__PACKAGE__->table('viroserve.extraction');
__PACKAGE__->sequence('viroserve.extraction_extraction_id_seq');
__PACKAGE__->columns(Primary =>
   qw[ extraction_id]
);
__PACKAGE__->columns(Essential => 
    qw[
        extract_type_id
        ]
);
__PACKAGE__->columns(Others => 
    qw[
        sample_id
        scientist_id
        protocol_id
        amount
        unit_id
        date_completed
        date_entered
        concentrated
        concentration
        concentration_unit_id
        eluted_vol
        eluted_vol_unit_id
        notes
        vv_uid
    ] 
);

__PACKAGE__->columns(TEMP => qw[type]);

__PACKAGE__->has_a(scientist_id => 'Viroverse::Model::scientist');
__PACKAGE__->has_a(extract_type_id => 'Viroverse::Model::extraction::type');
__PACKAGE__->has_many(pcr_template_id => 'Viroverse::Model::pcr_template');

__PACKAGE__->has_many(copy_numbers => 'Viroverse::Model::copy_number', {order_by => 'date_created DESC'});

__PACKAGE__->has_many(rt_products => 'Viroverse::Model::rt', 'extraction_id');
__PACKAGE__->has_a(unit_id => 'Viroverse::Model::unit');
__PACKAGE__->has_a(protocol_id => 'Viroverse::Model::protocol');
__PACKAGE__->has_a(concentration_unit_id => 'Viroverse::Model::unit');
__PACKAGE__->has_a(eluted_vol_unit_id => 'Viroverse::Model::unit');
__PACKAGE__->has_a(
    sample_id => 'ViroDB::Result::Sample',
    inflate => sub {
        return ViroDB->instance->resultset('Sample')->find($_[0]);
    },
    deflate => 'id',
);

__PACKAGE__->add_trigger(select => \&_setType);
__PACKAGE__->add_trigger(after_set_extract_type_id => \&_setType);

sub to_string {
    my $self = shift;

    return join(' ', map { $_ // "" }
                    $self->input_product->to_string,
                    $self->extract_type_id->get('name'),
                    'extracted ',$self->date_completed,
                    $self->concentration ? '('.$self->concentration.' '.$self->concentration_unit.')' : ''
                ); 
}

sub input_product { $_[0]->sample_id };
with 'Viroverse::Model::Role::MolecularProduct';

sub preferred_sequencing_na_type { $_[0]->extract_type_id->name };

sub amount_with_unit {
    my $self = shift;
    return if not $self->unit_id;
    return $self->unit_id->with_magnitude($self->amount);
}

sub concentration_unit {
    my $self = shift;
    return $self->concentration_unit_id ? $self->concentration_unit_id->name : '';
}

sub concentration_with_unit {
    my $self = shift;
    return if not $self->concentration_unit_id;
    return $self->concentration_unit_id->with_magnitude($self->concentration);
}

sub eluted_vol_unit {
    my $self = shift;
    return $self->eluted_vol_unit_id ? $self->eluted_vol_unit_id->name : '';
}

sub eluted_vol_with_unit {
    my $self = shift;
    return if not $self->eluted_vol_unit_id;
    return $self->eluted_vol_unit_id->with_magnitude($self->eluted_vol);
}

sub _setType {
       my $self = shift;
       if(! $self->type() && $self->extract_type_id()){
       $self->set(type =>  $self->extract_type_id->get('name'));  
       }else{
           $self->set(type =>  'foobar');  
       }
}

=item Viroverse::Model::extraction->longhand()
    Overides Viroverse::CDBI method to differentiate between DNA and RNA extractions
=cut

sub longhand {
       my $self = shift;
       my @all_columns  = $self->columns;
       my $shorthand = $self->SUPER::longhand();
       my $type = $self->type() ? $self->type() : $self->extract_type_id()->name();
       if($type eq "DNA"){
          return "$shorthand.dna";
       }elsif($type eq "RNA"){
          return "$shorthand.rna";;
       }
       
       warn "extraction type not set or set to " . $self->extract_type_id()->name() . "\n" ;
       return $shorthand;  #shouldn't happen
       
}

sub transform_search {
    my $self   = shift;
    my %search = (@_);

    $search{extract_type_id} = Viroverse::db::resolve_external_property(
        Viroverse::session->new($self->db_Main),
        'extract_type' => uc delete $search{na_type},
    ) if $search{na_type};

    return %search;
}

sub TO_JSON {
    my $self = shift;
    my %h = (
        id => $self->give_id,
        name => $self->to_string,
        completed => $self->date_completed,
        scientist_name => $self->scientist_id->name,
        sample_name => $self->sample_id ? $self->sample_id->to_string : '',
        tissue => $self->sample_id->$_call_if_object("tissue_type")->$_call_if_object("name") // '',
        concentration => $self->concentration,
        concentration_unit => $self->concentration_unit,
        eluted_vol => $self->eluted_vol,
        eluted_vol_unit => $self->eluted_vol_unit,
        extract_type    => ($self->extract_type_id ? $self->extract_type_id->name : undef),
        has_rt_products => (scalar @{[$self->rt_products]} ? \1 : \0),
    );

    return \%h;

}

1;
