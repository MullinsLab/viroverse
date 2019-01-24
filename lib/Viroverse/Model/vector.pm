package Viroverse::Model::vector;
use base 'Viroverse::CDBI';
use strict;
__PACKAGE__->table('viroserve.vector');
__PACKAGE__->columns(All =>
    qw[
        vector_id
        name
        ]
);

1;
