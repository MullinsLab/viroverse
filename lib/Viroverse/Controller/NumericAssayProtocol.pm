use strict;
use warnings;
use utf8;
use 5.018;

package Viroverse::Controller::NumericAssayProtocol;
use Moose;
use Try::Tiny;
use Catalyst::ResponseHelpers;
use namespace::autoclean;

BEGIN { extends 'Viroverse::Controller' }

sub base : Chained('/') PathPart('numeric-assay-protocol') CaptureArgs(0) {
    my ($self, $c) = @_;
    return Forbidden($c)
        unless $c->stash->{scientist}->is_admin;
}

sub create : POST Chained('base') PathPart('create') Args(0) {
    my ($self, $c) = @_;
    return ClientError($c, "Must supply a protocol name")
        unless defined $c->req->params->{name};
    return ClientError($c, "Must select a unit")
        unless defined $c->req->params->{unit_id};
    my $new_proto = $c->model("ViroDB::NumericAssayProtocol")
        ->create({
            name    => $c->req->params->{name},
            unit_id => $c->req->params->{unit_id},
        });
    my $mid = $c->set_status_msg("Added protocol " . $c->req->params->{name});
    return Redirect($c, $self->action_for('index'), [ ], { mid => $mid });
}

sub index : Chained('base') PathPart('') Args(0) {
    my ($self, $c) = @_;
    my @protocols = $c->model("ViroDB::NumericAssayProtocol")->search({}, {order_by => {-asc => "upper(name)"}})->all;
    my @units = $c->model("ViroDB::Unit")->order_by('name')->all;
    $c->stash(
        protocols => \@protocols,
        units     => \@units,
        template  => "numeric-assay-protocol/index.tt"
    );
    $c->detach($c->view('NG'));
}

1;
