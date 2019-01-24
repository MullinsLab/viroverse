package Viroverse::Model::copy_number_gel_lane;
use base 'Viroverse::CDBI';
use Carp;
use strict;

__PACKAGE__->table('viroserve.copy_number_gel_lane');
__PACKAGE__->columns(Primary =>
   qw[
    copy_number_id
        gel_lane_id
    ]
);

__PACKAGE__->has_a(copy_number_id => 'Viroverse::Model::copy_number');
__PACKAGE__->has_a(gel_lane_id => 'Viroverse::Model::gel_lane');

1;
