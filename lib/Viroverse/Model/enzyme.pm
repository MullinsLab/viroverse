package Viroverse::Model::enzyme;
use base 'Viroverse::CDBI';
use strict;

__PACKAGE__->table('viroserve.enzyme');
__PACKAGE__->columns(All => qw[
    enzyme_id
    name
    short_name
    type
]);

sub to_string {
    return $_[0]->name;
}

sub nickname {
    my $self = shift;
    return $self->short_name || $self->name;
}

sub search_rt {
    my $self = shift;
    return $self->search_where({ type => 'reverse transcriptase' });
}

sub search_pcr {
    my $self = shift;
    return $self->search_where({ type => 'polymerase' });
}

1;
