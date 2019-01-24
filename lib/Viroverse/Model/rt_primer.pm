package Viroverse::Model::rt_primer;
use base 'Viroverse::CDBI';
use strict;

__PACKAGE__->table('viroserve.rt_primer');

__PACKAGE__->columns(Primary => qw[
    rt_product_id
    primer_id
]);

__PACKAGE__->has_a(rt_product_id => 'Viroverse::Model::rt');
__PACKAGE__->has_a(primer_id => 'Viroverse::Model::primer');

1;
