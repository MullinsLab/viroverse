use 5.018;
use strict;
use warnings;
use utf8;

=encoding UTF-8

=head1 NAME

Viroverse::Search::Gel - Search gels by a variety of fields and facet results

=cut

package Viroverse::Search::Gel;
use Moo;
use Types::Standard qw< :types >;
use ViroDB;
use namespace::clean;

=head1 DESCRIPTION

This is a consumer of L<Viroverse::Search::Faceted> for searching gels.
Please read its documentation for usage information and additional details.

=cut

with "Viroverse::Search::Faceted";

has '+model',     isa => InstanceOf['ViroDB::ResultSet::Gel'];
has '+resultset', isa => InstanceOf['ViroDB::ResultSet::Gel'];

sub _build_model {
    return ViroDB->instance->resultset("Gel");
}

sub _build_id_field { "gel_id" }

sub _build_order_by {
    return [
        \['name ASC']
    ];
}

=head1 SEARCH FIELDS

The following are the accepted search fields which may be keys in L</query>.
Restrictions between different fields are ANDed while multiple values for a
single field are ORed.

All fields except L</freeform> are facetable.

=head2 freeform

Matches against the freeform text search fields.

=head2 scientist

Matches against the scientist who processed the gel.

=cut

sub _build_query_fields {
    return {
        freeform => {
            method => "search_freeform",
        },
        scientist => {
            method => "scientist",
            facet  => {
                column  => \["scientist.name"],
                label   => "Scientist",
                join    => "scientist",
            },
        },
    };
}

1;

