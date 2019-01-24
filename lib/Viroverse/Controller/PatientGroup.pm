use strict;
use warnings;
use utf8;
use 5.018;

package Viroverse::Controller::PatientGroup;

use Moose;
use Catalyst::ResponseHelpers;
use namespace::autoclean;

BEGIN { extends 'Viroverse::Controller' }

sub base : Chained('/') PathPart('patientgroup') CaptureArgs(0) { }

sub load : Chained('base') PathPart('') CaptureArgs(1) {
    my ($self, $c, $id) = @_;
    my $group = $c->model("ViroDB::PatientGroup")->find($id)
        or return NotFound($c, "No such patient group «$id»");
    $c->stash( current_model_instance => $group );
}

sub show : Chained('load') PathPart('') Args(0) {
    my ($self, $c) = @_;
    my @patients = $c->model->patient_summaries->distinct_by_patient->all;
    $c->stash(
        template => 'patientgroup/show.tt',
        group    => $c->model,
        patients => \@patients,
    );
    $c->detach( $c->view("NG") );
}

1;
