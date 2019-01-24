use strict;
use warnings;
use 5.018;
use utf8;

package Viroverse::Controller::Patient::Sequences;
use Moose;
use Viroverse::Search::Sequence;
use namespace::autoclean;

BEGIN { extends 'Viroverse::Controller' }

with 'Viroverse::Controller::Role::FacetedSearch';

has '+include_id_list', default => sub { 1 };

sub base : Chained('../load_by_id') PathPart('sequences') CaptureArgs(0) {
    my ($self, $c) = @_;

    my $params    = $c->request->params;
    my $sequences = $c->model("ViroDB::SequenceSearch")->search_rs(
        { patient_id => $c->model->give_id },
    );

    $c->stash(
        current_model_instance =>
            Viroverse::Search::Sequence->new(
                model => $sequences,
                query => $params,
                ($params->{rows} ? (rows => delete $params->{rows}) : ()),
                ($params->{page} ? (page => delete $params->{page}) : ()),
            )
    );
}

1;
