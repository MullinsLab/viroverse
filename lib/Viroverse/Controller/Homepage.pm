use strict;
use warnings;
use utf8;
use 5.018;

package Viroverse::Controller::Homepage;

use Moose;
use Catalyst::ResponseHelpers;
use Viroverse::Logger qw< :log >;
use List::Util qw< reduce >;
use Viroverse::config;
use namespace::autoclean;

BEGIN { extends 'Viroverse::Controller' }

sub base : Chained('/') PathPart('') CaptureArgs(0) { }

sub index : Chained('base') PathPart('') Args(0) {
    my ($self, $c) = @_;
    my $active     = $c->model("ViroDB::Project")->active;

    # The extensive prefetching below bundles a bunch of relationships into a
    # single fairly efficient query without resorting to a database view to
    # power the homepage.
    #
    # XXX TODO: I think we can reduce the amount of prefetching here if we
    # re-implement the Sample->date and Sample->patient methods on top of
    # joining to SamplePatientDate instead of calling a chain of accessors.
    # I assume that'd be better, but I'm not going to try it out now.
    #   -trs, 2 Feb 2018
    my @assignments = $active
        ->related_resultset('sample_assignments')
        ->search({ desig_scientist_id => $c->stash->{scientist}->id })
        ->prefetch(
            { 'sample' => [ 'search_data', 'tissue_type', { 'visit' => { 'patient' => { 'primary_aliases' => 'cohort' } } } ]  }
        )->prefetch('project')
        ->prefetch('progress')
        ->order_by({ -asc => [ \'coalesce(search_data.sample_date, visit.visit_date)', 'sample.name', 'sample.sample_id' ] })
        ->all;

    # Produce a hash of project name => assignments
    my $my_projects =
        reduce { push @{ $a->{ $b->project->name } ||= [] }, $b; $a }
            +{}, @assignments;

    my $nag = !$Viroverse::config::registered;

    $c->stash(
        template        => 'homepage/index.tt',
        active_projects => [ $active->order_by('name')->all ],
        my_projects     => $my_projects,
        nag             => $nag,
    );
    $c->detach( $c->view("NG") );
}

1;
