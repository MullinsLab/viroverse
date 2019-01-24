use 5.018;
use strict;
use warnings;

package Viroverse::API::Resource::Role::DBIC;
use Moo::Role;
use Types::Standard qw< InstanceOf >;
use namespace::clean;

requires '_build_rs';

has schema => (
    is  => 'ro',
    isa => InstanceOf['DBIx::Class::Schema'],
    required => 1,
);

has rs => (
    is  => 'lazy',
    isa => InstanceOf['DBIx::Class::ResultSet'],
);

1;
