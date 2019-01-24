package Viroverse::Model::alignment_method;
use base 'Viroverse::CDBI';
use strict;

__PACKAGE__->table('viroserve.alignment_method');
__PACKAGE__->columns(All => qw[
    alignment_method_id
    name
    ]
);

1;
