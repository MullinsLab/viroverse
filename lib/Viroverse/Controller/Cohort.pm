use strict;
use warnings;
use utf8;
use 5.018;

package Viroverse::Controller::Cohort;

use Moose;
use Catalyst::ResponseHelpers;
use namespace::autoclean;

BEGIN { extends 'Viroverse::Controller' }

sub base : Chained('/') PathPart('cohort') CaptureArgs(0) { }

sub index : Chained('base') PathPart('') Args(0) {
    my ($self, $c) = @_;
    my @cohorts = $c->model("ViroDB::Cohort")->search({}, { order_by => 'name' })->all;
    my @pt_groups = $c->model("ViroDB::PatientGroup")->search({}, { order_by => 'name' })->all;

    $c->stash(
        template => 'cohort/index.tt',
        cohorts  => \@cohorts,
        patient_groups => \@pt_groups,
    );
    $c->detach( $c->view("NG") );
}

sub load : Chained('base') PathPart('') CaptureArgs(1) {
    my ($self, $c, $id) = @_;

    my $key = $id =~ /\D/
        ? { name => $id }
        : $id;

    my $cohort = $c->model("ViroDB::Cohort")->find($key)
        or return NotFound($c, "No such cohort «$id»");

    # Canonicalize to numeric ids in the URL by redirecting to ourselves
    return Redirect($c, $c->action, [ $cohort->id ])
        if ref $key;

    $c->stash( current_model_instance => $cohort );
}

sub show : Chained('load') PathPart('') Args(0) {
    my ($self, $c) = @_;
    my @patients = $c->model->patient_summaries->all;
    $c->stash(
        template => 'cohort/show.tt',
        cohort   => $c->model,
        patients => \@patients,
    );
    $c->detach( $c->view("NG") );
}

1;
