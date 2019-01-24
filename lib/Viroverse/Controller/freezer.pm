package Viroverse::Controller::freezer;

use strict;
use warnings;
use base 'Viroverse::Controller';
use namespace::autoclean;

sub section { 'freezer' }

sub base : Chained('/') PathPart('freezer') CaptureArgs(0) {
    my ($self, $c) = @_;
    $c->stash(
        cohorts  => $c->model("ViroDB::Cohort")->list_all,
        freezers => [ $c->model("ViroDB::Freezer")->order_by(\'upper(name)')->all ],
    );
}

sub index : Chained('base') PathPart('') Args(0) {
    my ($self, $c) = @_;
    $c->controller('sidebar')->sidebar_to_stash($c);
    $c->stash( template => 'freezer_home.tt' );
    return $c->detach( $c->view('TT') );
}

1;
