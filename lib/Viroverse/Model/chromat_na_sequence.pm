package Viroverse::Model::chromat_na_sequence;
use Moo;
BEGIN { extends 'Viroverse::CDBI' };
__PACKAGE__->table('viroserve.chromat_na_sequence');
__PACKAGE__->columns(Essential =>
   qw[
        chromat_id
        na_sequence_id
        na_sequence_revision
    ]
);

__PACKAGE__->has_a(chromat_id => 'Viroverse::Model::chromat');
with 'Viroverse::Model::Role::HasSequence';

1;
