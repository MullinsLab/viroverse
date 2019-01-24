package Viroverse::Model::protocol_type;
use base 'Viroverse::CDBI';
use strict;
use warnings;

__PACKAGE__->table('viroserve.protocol_type');
__PACKAGE__->sequence('viroserve.protocol_type_protocol_type_id_seq');
__PACKAGE__->columns(All => qw[
    protocol_type_id
    name
]);

1;
