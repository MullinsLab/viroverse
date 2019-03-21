package Viroverse::Controller::freezer;

use strict;
use warnings;
use base 'Viroverse::Controller';
use Catalyst::ResponseHelpers;
use namespace::autoclean;

sub section { 'freezer' }

sub base : Chained('/') PathPart('freezer') CaptureArgs(0) {
    my ($self, $c) = @_;
    # Excluding browse-only users from the freezer UI entirely, which makes
    # sense in our conception of browse users as people involved in scientific
    # efforts but not lab operations.
    return Forbidden($c) unless $c->stash->{scientist}->can_edit;
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
