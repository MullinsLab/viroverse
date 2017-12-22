use strict;
use warnings;
use utf8;
use 5.018;

package Viroverse::Controller::Primer;
use Moose;
#use Catalyst::ResponseHelpers qw< :helpers :status >;
#use JSON::MaybeXS;
use namespace::autoclean;

BEGIN { extends 'Viroverse::Controller' }

sub base : Chained('/') PathPart('primer') CaptureArgs(0) { }

sub index : Chained('base') PathPart('') Args(0) {
    my ($self, $c) = @_;
    $c->stash( template => 'primer/index.tt' );
    $c->detach( $c->view("NG") );
}

1;
