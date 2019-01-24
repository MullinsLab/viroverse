use strict;
use warnings;
use utf8;
use 5.018;

package Viroverse::Controller::TissueType;
use Moose;
use Catalyst::ResponseHelpers;
use namespace::autoclean;

BEGIN { extends 'Viroverse::Controller' }

sub base : Chained('/') PathPart('tissue') CaptureArgs(0) {
    my ($self, $c) = @_;
    return Forbidden($c)
        unless $c->stash->{scientist}->is_admin;
}

sub index : Chained('base') PathPart('') Args(0) {
    my ($self, $c) = @_;
    my @tissues = $c->model("ViroDB::TissueType")->search({},
        {
            order_by  => [ { -desc => \"count(samples.sample_id)" }, { -asc => "me.name" } ],
            join      => 'samples',
            '+select' => [ { count => 'samples.sample_id', } ],
            '+as'     => [qw[ sample_count ]],
            group_by  => [ 'me.tissue_type_id', 'me.name' ]
        })->all;
    $c->stash(
        tissue_types => \@tissues,
        template => "tissue/index.tt"
    );
    $c->detach($c->view('NG'));
}

sub create : POST Chained('base') PathPart('') Args(0) {
    my ($self, $c) = @_;
    return ClientError($c, "Must supply a tissue type name")
        unless defined $c->req->params->{name};
    my $new_tissue = $c->model("ViroDB::TissueType")
        ->create({ name => $c->req->params->{name} });
    my $mid = $c->set_status_msg("Added tissue type " . $c->req->params->{name});
    return Redirect($c, $self->action_for('index'), { mid => $mid });
}


1;
