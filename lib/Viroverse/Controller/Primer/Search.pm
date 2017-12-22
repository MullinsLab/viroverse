use strict;
use warnings;
use 5.018;
use utf8;

package Viroverse::Controller::Primer::Search;
use Moose;
use Viroverse::Search::Primer;
use namespace::autoclean;

BEGIN { extends 'Viroverse::Controller' }

with 'Viroverse::Controller::Role::FacetedSearch';

sub base : ChainedParent PathPart('search') CaptureArgs(0) {
    my ($self, $c) = @_;
    my $params = $c->request->params;
    $c->stash(
        current_model_instance =>
            Viroverse::Search::Primer->new(
                query => $params,
                ($params->{rows} ? (rows => delete $params->{rows}) : ()),
                ($params->{page} ? (page => delete $params->{page}) : ()),
            )
    );
}

1
