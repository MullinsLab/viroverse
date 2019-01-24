use strict;
use warnings;
use 5.018;
use utf8;

package Viroverse::Controller::Patient::Samples;
use Moose;
use Viroverse::Search::Sample;
use namespace::autoclean;

BEGIN { extends 'Viroverse::Controller' }

with 'Viroverse::Controller::Role::FacetedSearch';

sub base : Chained('../load_by_id') PathPart('samples') CaptureArgs(0) {
    my ($self, $c) = @_;

    my $params  = $c->request->params;
    my $samples = $c->model("ViroDB::DistinctSampleSearch")->search_rs({
        patient_id => $c->model->give_id
    });

    $c->stash(
        current_model_instance =>
            Viroverse::Search::Sample->new(
                model => $samples,
                query => $params,
                ($params->{rows} ? (rows => delete $params->{rows}) : ()),
                ($params->{page} ? (page => delete $params->{page}) : ()),
            )
    );
}

1;
