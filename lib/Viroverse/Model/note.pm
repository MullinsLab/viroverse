use strict;
use warnings;

package Viroverse::Model::note;
use base 'Viroverse::CDBI';

__PACKAGE__->table('viroserve.notes');
__PACKAGE__->sequence('viroserve.notes_note_id_seq');

__PACKAGE__->columns(All => qw[
    note_id
    vv_uid
    scientist_id
    private
    note
    date_added
]);

__PACKAGE__->has_a(scientist_id => 'Viroverse::Model::scientist');

1;
