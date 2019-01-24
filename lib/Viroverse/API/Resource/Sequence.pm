use 5.018;
use strict;
use warnings;
use utf8;

package Viroverse::API::Resource::Sequence;
use Moo;

use Types::Standard qw< InstanceOf Maybe >;
use Web::Machine::Util qw< bind_path >;
use Viroverse::Logger qw< :log :dlog >;
use namespace::clean;

extends 'Viroverse::API::Resource';

has sequence_id => (
    is => 'rwp',
);

has sequence => (
    is  => 'lazy',
    isa => Maybe[InstanceOf['Viroverse::Model::sequence::dna']],
);

sub _build_sequence {
    my $self = shift;
    my $id = $self->sequence_id;

    log_debug { "fetching sequence #$id" };
    my $seq = Viroverse::Model::sequence::dna->retrieve($id)
        or log_debug { "sequence #$id not found" };
    return $seq;
}

sub malformed_request {
    my $self = shift;
    my $id = bind_path('/:id', $self->request->path_info);
    return $self->error_as_json( \400 => "No sequence ID provided" )
        unless defined $id;
    $self->_set_sequence_id($id);
    return 0;
}

sub allowed_methods { ['GET', 'HEAD', 'DELETE'] }

sub resource_exists {
    $_[0]->sequence and $_[0]->sequence->na_sequence_id
}

sub to_data {
    $_[0]->sequence->to_hash
}

sub delete_resource {
    my $self = shift;
    my $seq  = $self->sequence;
    my $sci  = $self->current_scientist;
    my $why  = $self->request->param('reason');

    my ($ok, $msg) = $seq->mark_deleted_by($sci, $why);
    $self->error_as_json( \500 => $msg ) unless $ok;
    return $ok;
}

1;
