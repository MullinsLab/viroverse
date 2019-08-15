use strict;
use warnings;
use 5.018;
use utf8;

package Viroverse::Controller::PacBioSequencing::PoolSearch;
use Moose;
use Viroverse::Search::PacbioPool;
use namespace::autoclean;

BEGIN { extends 'Viroverse::Controller' }

with 'Viroverse::Controller::Role::FacetedSearch';

sub base : ChainedParent PathPart('search') CaptureArgs(0) {
    my ($self, $c) = @_;
    my $params = $c->request->params;

    my ($rows, $page) = delete @$params{qw[ rows page ]};

    $self->include_id_list( keys %$params > 0 );

    $c->stash(
        current_model_instance =>
            Viroverse::Search::PacbioPool->new(
                query => $params,
                ($rows ? (rows => $rows) : ()),
                ($page ? (page => $page) : ()),
            )
    );
}

1;
