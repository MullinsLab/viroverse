package Viroverse::Model::protocol;
use base 'Viroverse::CDBI';
use Carp qw[croak];
use strict;

__PACKAGE__->table('viroserve.protocol');
__PACKAGE__->sequence('viroserve.protocol_protocol_id_seq');
__PACKAGE__->columns(All => qw[
    protocol_id
    name
    last_revision
    source
]);

__PACKAGE__->columns(Others => qw[ protocol_type_id ]);

__PACKAGE__->has_a(protocol_type_id => 'Viroverse::Model::protocol_type');

__PACKAGE__->set_sql(by_type => qq{
    SELECT __ESSENTIAL__
      FROM __TABLE__
      JOIN viroserve.protocol_type USING (protocol_type_id)
     WHERE protocol_type.name = lower(?)
     ORDER BY lower(protocol.name)
});

__PACKAGE__->set_sql(by_type_and_name => qq{
    SELECT __ESSENTIAL__
      FROM __TABLE__
      JOIN viroserve.protocol_type USING (protocol_type_id)
     WHERE protocol_type.name = lower(?)
       AND __TABLE__.name = ?
     ORDER BY lower(protocol.name)
});

sub to_string {
    return $_[0]->name;
}

1;
