use strict;
use warnings;
use utf8;
use 5.018;

package Viroverse::Controller::Project;

use Moose;
use Catalyst::ResponseHelpers;
use List::MoreUtils qw< part >;
use namespace::autoclean;

BEGIN { extends 'Viroverse::Controller' }

sub base : Chained('/') PathPart('project') CaptureArgs(0) { }

sub index : Chained('base') PathPart('') Args(0) {
    my ($self, $c) = @_;
    my $projects = $c->model("ViroDB::Project")->search({}, { order_by => 'name' });
    my @active = $projects->active->all;
    my @completed = $projects->completed->all;

    $c->stash(
        template           => 'project/index.tt',
        active_projects    => \@active,
        completed_projects => \@completed,
    );
    $c->detach('Viroverse::View::NG');
}

sub load : Chained('base') PathPart('') CaptureArgs(1) {
    my ($self, $c, $id) = @_;
    my $project = $c->model("ViroDB::Project")->find($id)
        or return NotFound($c, "No such project «$id»");
    $c->stash( current_model_instance => $project );
}

sub show : Chained('load') PathPart('') Args(0) {
    my ($self, $c) = @_;
    $c->stash(
        template => 'project/show.tt',
        project  => $c->model,
    );
    $c->detach('Viroverse::View::NG');
}

sub assigned_samples_for_scientist : Chained('load') PathPart('scientist') Args(1) {
    my ($self, $c, $scientist_id) = @_;
    my $this_scientist = $c->model("ViroDB::Scientist")->find($scientist_id)
        or return NotFound($c, "No such scientist «$scientist_id»");
    my @project_samples = $c->model->search_related('sample_assignments',
        { desig_scientist_id  => $this_scientist->id }
    )->all;
    $c->stash(
        project         => $c->model,
        project_samples => \@project_samples,
        this_scientist  => $this_scientist,
        template        => 'project/assigned-samples-for-scientist.tt',
    );
    $c->detach('Viroverse::View::NG');
}

1;
