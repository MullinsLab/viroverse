package Viroverse::Model::gel_lane::special;
use strict;
use base 'Class::Accessor';

__PACKAGE__->mk_accessors('name','pos_neg');

sub non_product {
    return 1;
}

sub to_string {
    return $_[0]->name;
}

sub table {
    return undef;
}

sub columns {
    return undef;
}

1;
