package Viroverse::Model::visit;
use Moo;
BEGIN { extends 'Viroverse::CDBI' }

__PACKAGE__->table('viroserve.visit');
__PACKAGE__->sequence('viroserve.visit_visit_id_seq');
__PACKAGE__->columns(All => qw[
    visit_id
    patient_id
    visit_date
    visit_number
    vv_uid
    date_entered
    is_deleted
]);

1;
