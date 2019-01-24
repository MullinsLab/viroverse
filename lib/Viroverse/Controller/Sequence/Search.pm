use strict;
use warnings;
use 5.018;
use utf8;

package Viroverse::Controller::Sequence::Search;
use Moose;
use Viroverse::Search::Sequence;
use namespace::autoclean;

BEGIN { extends 'Viroverse::Controller' }

with 'Viroverse::Controller::Role::FacetedSearch';

has '+include_id_list', default => sub { 1 };

sub base : ChainedParent PathPart('search') CaptureArgs(0) {
    my ($self, $c) = @_;
    my $params = $c->request->params;

    my ($rows, $page) = delete @$params{qw[ rows page ]};

    # Only include ids if the search is limited in some way.  This greatly
    # speeds up the initial page load.  Notably, the UI doesn't need the id
    # list on an unlimited search, so no functionality is lost.  A _better_ way
    # to fix this is to make the id list unnecessary at _all_ times, but that
    # requires a broader scope of changes to sequence downloading and sidebar
    # handling.  I have a rough cut of that but it isn't quite there.  Until I
    # have some more time to spend on that, this workaround will do!
    #
    # This isn't as big a deal on other sequence search endpoints as they are
    # inherently limited by their scope to a patient or sample.  As such, I
    # haven't modified them.
    #   -trs, 12 Oct 2017
    $self->include_id_list( keys %$params > 0 );

    $c->stash(
        current_model_instance =>
            Viroverse::Search::Sequence->new(
                query => $params,
                ($rows ? (rows => $rows) : ()),
                ($page ? (page => $page) : ()),
            )
    );
}

1;
