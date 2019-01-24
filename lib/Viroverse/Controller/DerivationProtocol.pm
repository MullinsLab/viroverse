use strict;
use warnings;
use utf8;
use 5.018;

package Viroverse::Controller::DerivationProtocol;
use Moose;
use Try::Tiny;
use Catalyst::ResponseHelpers;
use namespace::autoclean;

BEGIN { extends 'Viroverse::Controller' }

sub base : Chained('/') PathPart('protocol') CaptureArgs(0) {
    my ($self, $c) = @_;
    return Forbidden($c)
        unless $c->stash->{scientist}->is_admin;
}

sub create : POST Chained('base') PathPart('create') Args(0) {
    my ($self, $c) = @_;
    return ClientError($c, "Must supply a protocol name")
        unless defined $c->req->params->{name};
    my $new_proto = $c->model("ViroDB::DerivationProtocol")
        ->create({ name => $c->req->params->{name} });
    my $mid = $c->set_status_msg("Added protocol " . $c->req->params->{name});
    return Redirect($c, $self->action_for('show'), [ $new_proto->id ], { mid => $mid });
}

sub index : Chained('base') PathPart('') Args(0) {
    my ($self, $c) = @_;
    my @protocols = $c->model("ViroDB::DerivationProtocol")->search({}, {order_by => {-asc => "upper(name)"}})->all;
    $c->stash(
        protocols => \@protocols,
        template => "protocol/index.tt"
    );
    $c->detach($c->view('NG'));
}

sub load : Chained('base') PathPart('') CaptureArgs(1) {
    my ($self, $c, $id) = @_;
    my $protocol = $c->model("ViroDB::DerivationProtocol")->find($id)
        or return NotFound($c, "No such protocol «$id»");
    $c->stash( current_model_instance => $protocol );
}

sub show : Chained('load') PathPart('') Args(0) {
    my ($self, $c) = @_;
    my @tissues = $c->model("ViroDB::TissueType")->search({}, {order_by => {-asc => "upper(name)"}});
    $c->stash(
        template     => 'protocol/show.tt',
        protocol     => $c->model,
        tissue_types => \@tissues,
    );
    $c->detach($c->view('NG'));
}

sub add_output : POST Chained('load') PathPart('add_output') Args(0) {
    my ($self, $c)= @_;
    my $tissue_type = $c->model("ViroDB::TissueType")->find($c->req->params->{tissue_type_id});
    try {
        $c->model->protocol_outputs->create({ tissue_type => $tissue_type });
    } catch {
        my $error = $_ =~ s/ at \S+ line \d+.*//rs;
        my $mid = $c->set_error_msg("Error adding protocol output: $error");
        $c->res->redirect( $c->uri_for_action($self->action_for('show'), [$c->model->id], { mid => $mid }) );
        $c->detach;
    };
    $c->res->redirect( $c->uri_for_action($self->action_for('show'), [$c->model->id]) );
}

1;
