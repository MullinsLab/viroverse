package Viroverse::Model::Role::HasSequence;

use strict;
use warnings;

use Moose::Role;
use Viroverse::Model::sequence::dna;
use namespace::autoclean;

requires 'na_sequence_id';
requires 'na_sequence_revision';

sub na_sequence {
    my $self = shift;
    return Viroverse::Model::sequence::dna->retrieve($self->na_sequence_id, $self->na_sequence_revision);
}

1;
