package Viroverse::Model::pcr_pool_pcr_product;
use base 'Viroverse::CDBI';
use strict;
use warnings;

__PACKAGE__->table('viroserve.pcr_pool_pcr_product');
__PACKAGE__->columns(Primary =>
    qw[
        pcr_pool_id
        pcr_product_id
        ]
);

__PACKAGE__->has_a(pcr_product_id => 'Viroverse::Model::pcr');
__PACKAGE__->has_a(pcr_pool_id => 'Viroverse::Model::pcr_pool');

1;
