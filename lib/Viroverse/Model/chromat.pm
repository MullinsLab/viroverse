package Viroverse::Model::chromat;
use Moo;
BEGIN { extends 'Viroverse::CDBI' }
use Carp qw[croak];
use Viroverse::Model::chromat_type;

with 'Viroverse::Model::enumerable';

__PACKAGE__->table('viroserve.chromat');
__PACKAGE__->sequence('viroserve.chromat_chromat_id_seq');
__PACKAGE__->columns(Essential =>
   qw[
        chromat_id
        vv_uid
        date_entered
        name
    ]
);
__PACKAGE__->columns(Others => qw[
        data
        primer_id
        scientist_id
        chromat_type_id
      ] 
);

__PACKAGE__->data_type(data => {pg_type => DBD::Pg::PG_BYTEA});

__PACKAGE__->has_a(scientist_id => 'Viroverse::Model::scientist');
__PACKAGE__->has_a(chromat_type_id => 'Viroverse::Model::chromat_type');
__PACKAGE__->has_a(primer_id => 'Viroverse::Model::primer');
__PACKAGE__->has_many(na_sequences => ['Viroverse::Model::chromat_na_sequence' => 'na_sequence']);


sub insert {
    die "Inserting chromats through the CDBI model is disabled!";
}

sub to_string {
    return $_[0]->name;
}

sub TO_JSON {
    my $self = shift;
    return {
        id=> $self->give_id,
        name=> $self->to_string,
        added=> $self->date_entered,
        scientist_name=> $self->scientist_id->name,
    };
}

sub transform_search {
    my $self   = shift;
    my %search = (@_);

    $search{date_entered} = delete $search{date_completed}
        if $search{date_completed};

    return %search;
}

1;
