package Viroverse::Controller::admin;

use strict;
use warnings;
use base 'Viroverse::Controller';

sub section { 'admin' }

sub base : Chained('/') PathPart('admin') CaptureArgs(0) { }

sub index : Chained('base') PathPart('') Args(0) {
    my ($self, $c) = @_;
    $c->stash( template => 'admin_home.tt' );
}

1;
