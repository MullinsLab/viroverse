use 5.018;
use strict;
use warnings;
use utf8;

=encoding UTF-8

=head1 NAME

Viroverse::Search::Primer - Search primers by a variety of fields and facet results

=head1 SYNOPSIS

    my $search = Viroverse::Search::Primer->new(
        query => {
            organism => "HIV-1"
        }
    );

    say "Matched ", $search->count, " primers";

    # First 10 results, as ViroDB::Result::Primer objects
    my @results = $search->results;

=cut

package Viroverse::Search::Primer;
use Moo;
use Types::Standard qw< :types >;
use ViroDB;
use namespace::clean;

=head1 DESCRIPTION

This is a consumer of L<Viroverse::Search::Faceted> for searching primers.
Please read its documentation for usage information and additional details.

=cut

with "Viroverse::Search::Faceted";

has '+model',     isa => InstanceOf['ViroDB::ResultSet::PrimerSearch'];
has '+resultset', isa => InstanceOf['ViroDB::ResultSet::PrimerSearch'];

sub _build_model {
    return ViroDB->instance->resultset("PrimerSearch");
}

sub _build_id_field { "primer_id" }

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

Matches against the primer name, notes, and sequence contents. Strings are
tokenized by whitespace, which is the same as providing an arrayref of strings.

=head2 organism

Matches against the organism of the primer.

=cut

sub _build_query_fields {
    return {
        freeform => {
            method => "search_freeform",
        },
        organism => {
            method => "organism",
            facet  => {
                column  => "organism",
                label   => "Organism",
            },
        },
        orientation => {
            method => "orientation",
            facet  => {
                column  => "orientation",
                label   => "Orientation",
            },
        },
    };
}

1;

