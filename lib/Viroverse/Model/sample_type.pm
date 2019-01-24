package Viroverse::Model::sample_type;
use base 'Viroverse::CDBI';
use strict;

__PACKAGE__->table('viroserve.sample_type');
__PACKAGE__->columns(All =>
       qw[
            sample_type_id
            name
          ] 
    );




sub list{
    my $start = shift;
    my @objs;
    if ($start) {
        @objs = Viroverse::Model::sample_type->search_ilike( name => "$start%", {order_by=>'name'} );
    } else {
        @objs = Viroverse::Model::sample_type->retrieve_all_sorted_by('name');
    }

    my @retVal = map { {id => $_->sample_type_id, name => $_->name } } @objs ;
        return @retVal;
}

1;
