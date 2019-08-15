use strict;
use warnings;
use utf8;
use 5.018;

package Viroverse::Controller::Gel;
use Moose;
use Catalyst::ResponseHelpers qw< :helpers :status >;
use namespace::autoclean;

BEGIN { extends 'Viroverse::Controller' }

sub base : Chained('/') PathPart('gel') CaptureArgs(0) { }

sub index : Chained('base') PathPart('') Args(0) {
    my ($self, $c) = @_;
    $c->stash( template => 'gel/index.tt' );
    $c->detach( $c->view("NG") );
}

1;
