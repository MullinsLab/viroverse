package Viroverse::Model::enumerable;

use Moose::Role;
use strict;

sub TO_JSON {
    my $self = shift;

    return {
        id => $self->give_id,
        name => $self->to_string,
        completed => $self->date_completed,
        scientist_name=> $self->scientist_id->name,
    }
}

1;
