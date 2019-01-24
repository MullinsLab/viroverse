use strict;
use warnings;
use 5.018;
use utf8;

package Viroverse::Controller::Sample::IceCultures;
use Moose;
use Viroverse::Search::Sample;
use namespace::autoclean;
use Catalyst::ResponseHelpers qw< :helpers :status >;


BEGIN { extends 'Viroverse::Controller' }

with 'Viroverse::Controller::Role::FacetedSearch';

sub base : Chained('../load') PathPart('ice-cultures') CaptureArgs(0) {
    my ($self, $c) = @_;

    unless ($c->stash->{features}->{ice_cultures}) {
        return NotFound($c, "Feature disabled: ICE cultures");
    }

    my $params       = $c->request->params;
    my $ice_cultures = $c->model->ice_cultures->related_resultset('search_data');

    $c->stash(
        current_model_instance =>
            Viroverse::Search::Sample->new(
                model => $ice_cultures,
                query => $params,
                ($params->{rows} ? (rows => delete $params->{rows}) : ()),
                ($params->{page} ? (page => delete $params->{page}) : ()),
            )
    );
}

1;
