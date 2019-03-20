package Viroverse::Controller::admin;

use strict;
use warnings;
use base 'Viroverse::Controller';
use Catalyst::ResponseHelpers;

sub section { 'admin' }

sub base : Chained('/') PathPart('admin') CaptureArgs(0) {
    my ($self, $c) = @_;
    # the 'admin' index houses links to the freezer stuff, which all editors
    # can browse, so we only block browsers from checking it out
    return Forbidden($c) unless $c->stash->{scientist}->can_edit;
}

sub index : Chained('base') PathPart('') Args(0) {
    my ($self, $c) = @_;
    $c->stash( template => 'admin_home.tt' );
}

1;
