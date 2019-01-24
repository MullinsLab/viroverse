package Viroverse::Model::pcr_primer;
use base 'Viroverse::CDBI';

use strict;
use warnings;

__PACKAGE__->table('viroserve.pcr_product_primer');
__PACKAGE__->columns(Primary =>
    qw[
        pcr_product_id
        primer_id
        ]
);

__PACKAGE__->has_a(pcr_product_id => 'Viroverse::Model::pcr');
__PACKAGE__->has_a(primer_id => 'Viroverse::Model::primer');

1;
