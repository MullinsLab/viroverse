use 5.018;
use strict;
use warnings;
use utf8;

=encoding UTF-8

=head1 NAME

Viroverse::Search::Sequence - Search sequences by a variety of fields and facet results

=head1 SYNOPSIS

    my $search = Viroverse::Search::Sequence->new(
        query => {
            tissue_type => "brain"
        }
    );
    
    say "Matched ", $search->count, " sequences";
    
    # First 10 results, as ViroDB::Result::SequenceSearch objects
    my @results = $search->results;

=cut

package Viroverse::Search::Sequence;
use Moo;
use Types::Standard qw< :types >;
use ViroDB;
use namespace::clean;

=head1 DESCRIPTION

This is a consumer of L<Viroverse::Search::Faceted> for searching sequences.
Please read its documentation for usage information and additional details.

Sequences are ordered by date entered, most recent first, and then name.

=cut

with "Viroverse::Search::Faceted";

has '+model',     isa => InstanceOf['ViroDB::ResultSet::SequenceSearch'];
has '+resultset', isa => InstanceOf['ViroDB::ResultSet::SequenceSearch'];

sub _build_model {
    return ViroDB->instance->resultset("SequenceSearch");
}

sub _build_id_field { "na_sequence_id" }

sub _build_order_by {
    return [
        { -desc => 'entered_date' },
        { -asc  => 'name' }
    ];
}


=head1 SEARCH FIELDS

The following are the accepted search fields which may be keys in L</query>.
Restrictions between different fields are ANDed while multiple values for a
single field are ORed.

All fields except L</freeform> are facetable.

=head2 freeform

Matches against the sequence accession, name, and PCR name.  Strings are
tokenized by whitespace, which is the same as providing an arrayref of strings.

=head2 na_type

Matches against the type of nucleic acid which was sequenced (DNA or RNA).

=head2 tissue_type

Matches against the tissue type of the sample which was sequenced.

=head2 cohort

Matches against the cohorts of the patient whose sample was sequenced.

=head2 region

Matches against the genomic regions the sequence overlaps.  The large amplicons
NFLG, LH, and RH are also included as regions.

=head2 scientist

Matches against the full name of the scientist who submitted the sequence.

=head2 type

Matches against the sequencing type used (e.g. Genomic, Bisulfite).

=cut

sub _build_query_fields {
    return {
        freeform => {
            method => "search_freeform",
        },
        na_type => {
            method => "na_type",
            facet  => {
                column  => "na_type",
                label   => "NA Type",
            },
        },
        tissue_type => {
            method => "tissue_type",
            facet  => {
                column  => "tissue_type",
                label   => "Tissue",
            },
        },
        cohort => {
            method => "cohort",
            facet  => {
                column  => \["unnest(cohorts)"],
                label   => "Cohort",
            },
        },
        region => {
            method => "region",
            facet  => {
                column  => \["unnest(regions)"],
                label   => "Region",
            },
        },
        scientist => {
            method => "scientist",
            facet  => {
                column  => "scientist",
                label   => "Scientist",
            },
        },
        type => {
            method => "type",
            facet  => {
                column  => "type",
                label   => "Type",
            },
        },
    };
}

1;
