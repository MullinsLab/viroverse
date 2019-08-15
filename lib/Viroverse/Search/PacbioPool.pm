use 5.018;
use strict;
use warnings;
use utf8;

=encoding UTF-8

=head1 NAME

Viroverse::Search::PacbioPool

=cut

package Viroverse::Search::PacbioPool;
use Moo;
use Types::Standard qw< :types >;
use ViroDB;
use namespace::clean;

=head1 DESCRIPTION

This is a consumer of L<Viroverse::Search::Faceted> for searching certain PCR
products.  Please read the role's documentation for usage information and
additional details.

=cut

with "Viroverse::Search::Faceted";

has '+model',     isa => InstanceOf['ViroDB::ResultSet::PacbioPool'];
has '+resultset', isa => InstanceOf['ViroDB::ResultSet::PacbioPool'];

sub _build_model {
    return ViroDB->instance->resultset("PacbioPool");
}

sub _build_id_field { "pcr_product_id" }

sub _build_order_by {
    return [
        { -desc => 'date_completed' },
        { -asc  => 'sample_name' }
    ];
}


=head1 SEARCH FIELDS

The following are the accepted search fields which may be keys in L</query>.
Restrictions between different fields are ANDed while multiple values for a
single field are ORed.

All fields except L</freeform> are facetable.

=head2 freeform

Matches against the sample name and PCR nickname. Strings are tokenized by
whitespace, which is the same as providing an arrayref of strings.

=head2 scientist

Matches against the full name of the scientist who performed the PCR.

=head2 rt_primer

Matches against the name of the RT primer used to affix a sample ID for
multiplexing and establish one end of the amplicon.

=cut

sub _build_query_fields {
    return {
        freeform => {
            method => "search_freeform",
        },
        scientist => {
            method => "scientist",
            facet  => {
                column  => "scientist",
                label   => "Scientist",
            },
        },
        rt_primer => {
            method => "rt_primer",
            facet  => {
                column  => "rt_primer",
                label   => "RT Primer",
            },
        },
    };
}

1;
