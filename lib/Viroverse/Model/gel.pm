package Viroverse::Model::gel;
use Moo;
BEGIN { extends 'Viroverse::CDBI' }

with 'Viroverse::Model::enumerable';

__PACKAGE__->table('viroserve.gel');
__PACKAGE__->sequence('viroserve.gel_gel_id_seq');
__PACKAGE__->columns(Essential =>
   qw[
            gel_id
            scientist_id
            name
            vv_uid
      ] 
);

__PACKAGE__->columns(Others =>
   qw[
            protocol_id
            date_completed
            date_entered
            notes
            mime_type
            image
            ninety_six_well
        ]
);

# NB comments on http://wiki.class-dbi.com/wiki/Working_with_blobs imply that this sets the data type
# for every column named image (regardless of class or table)
__PACKAGE__->data_type(image => {pg_type => DBD::Pg::PG_BYTEA});

__PACKAGE__->has_a(scientist_id => 'Viroverse::Model::scientist');
__PACKAGE__->has_many(lanes => 'Viroverse::Model::gel_lane', {order_by => 'label::int'});

sub to_string {
    my $self = shift;

    return $self->name;
}

sub TO_JSON {
    my $self = shift;

    return {
        id=> $self->give_id,
        name=> $self->to_string,
        entered=> $self->date_entered,
        scientist_name=> $self->scientist_id->name,
    }
}

sub transform_search {
    my $self   = shift;
    my %search = (@_);

    $search{date_entered} = delete $search{date_completed}
        if $search{date_completed};

    return %search;
}

1;
