use strict;
use warnings;
use utf8;
use 5.018;

package Viroverse::Controller::Enzyme;
use Moose;
use Catalyst::ResponseHelpers;
use namespace::autoclean;

BEGIN { extends 'Viroverse::Controller' }

sub base : Chained('/') PathPart('enzyme') CaptureArgs(0) {
    my ($self, $c) = @_;
    return Forbidden($c)
        unless $c->stash->{scientist}->is_admin;
}

sub index : Chained('base') PathPart('') Args(0) {
    my ($self, $c) = @_;
    my @enzymes = $c->model("ViroDB::Enzyme")->order_by('name')->all;
    $c->stash(
        enzymes => \@enzymes,
        template => "enzyme/index.tt"
    );
    $c->detach($c->view('NG'));
}

sub create : POST Chained('base') PathPart('') Args(0) {
    my ($self, $c) = @_;
    return ClientError($c, "Must supply an enzyme name")
        unless defined $c->req->params->{name};
    return ClientError($c, "Must supply an enzyme type")
        unless defined $c->req->params->{type};
    my $new_enzyme = $c->model("ViroDB::Enzyme")
        ->create({
            name => $c->req->params->{name},
            type => $c->req->params->{type}
        });
    my $mid = $c->set_status_msg("Added enzyme " . $c->req->params->{name});
    return Redirect($c, $self->action_for('index'), { mid => $mid });
}


1;
