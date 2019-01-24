package Viroverse::Model::extraction::type;
use base 'Viroverse::CDBI';

__PACKAGE__->table('viroserve.extract_type');
__PACKAGE__->columns(All =>
   qw[
        extract_type_id
        name
    ]
);

1;
