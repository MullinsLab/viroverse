use utf8;
use strict;
use warnings;
package Viroverse::Controller::Role::FacetedSearch;
use MooseX::MethodAttributes::Role;
use Catalyst::ResponseHelpers;
use JSON::MaybeXS;
use Types::Standard qw< :types >;
use Viroverse::Logger qw< :log :dlog >;
use namespace::autoclean;

requires 'base';

has include_id_list => (
    is      => 'rw',
    isa     => Bool,
    default => sub { 0 },
);

my $SearchModel = ConsumerOf['Viroverse::Search::Faceted'];

sub search : Chained('base') PathPart('') Args(0)
           : Does(MatchRequestAccepts) Accept('application/json') {
    my ($self, $c) = @_;
    $SearchModel->assert_valid($c->model);

    my $search = $c->model;

    Dlog_debug { "Faceted search query: $_" } $search->query;

    my $response = {
        facets  => $search->facets,
        total   => $search->count + 0,
        rows    => [ $search->results ],
        ($self->include_id_list
            ? (ids => $search->ids)
            : ()),
    };

    # XXX TODO: Use AsJSON once our View::JSON and View::JSON2 aren't stupid.
    # -trs, 22 Nov 2016
    return FromCharString($c,
        JSON->new->convert_blessed->encode($response),
        'application/json; charset=UTF-8'
    );
}

1;
