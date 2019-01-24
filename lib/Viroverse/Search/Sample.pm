use 5.018;
use strict;
use warnings;
use utf8;

=encoding UTF-8

=head1 NAME

Viroverse::Search::Sample - Search samples by a variety of fields and facet results

=head1 SYNOPSIS

    my $search = Viroverse::Search::Sample->new(
        query => {
            tissue_type => "brain"
        }
    );
    
    say "Matched ", $search->count, " samples";
    
    # First 10 results, as ViroDB::Result::SampleSearch objects
    my @results = $search->results;

=cut

package Viroverse::Search::Sample;
use Moo;
use Types::Standard qw< :types >;
use ViroDB;
use namespace::clean;

=head1 DESCRIPTION

This is a consumer of L<Viroverse::Search::Faceted> for searching samples.
Please read its documentation for usage information and additional details.

Samples are ordered by their sample date, latest first.

=cut

with "Viroverse::Search::Faceted";

has '+model',     isa => InstanceOf['ViroDB::ResultSet::DistinctSampleSearch'];
has '+resultset', isa => InstanceOf['ViroDB::ResultSet::DistinctSampleSearch'];

sub _build_model {
    return ViroDB->instance->resultset("DistinctSampleSearch");
}

sub _build_id_field { "sample_id" }

sub _build_order_by {
    return [
        \['sample_date DESC NULLS LAST']
    ];
}


=head1 SEARCH FIELDS

The following are the accepted search fields which may be keys in L</query>.
Restrictions between different fields are ANDed while multiple values for a
single field are ORed.

All fields except L</freeform> are facetable.

=head2 freeform

Matches against the sample name.  Strings are tokenized by whitespace, which is
the same as providing an arrayref of strings.

=head2 has_sequences

If true, matches samples with associated sequences.  If false, matches samples
without associated sequences.  If omitted, no restrictions on related sequences
are imposed.

=head2 has_quantifiable_viral_load

If true, matches samples with a quantifiable viral load.  If false, matches
samples with an unquantifiable viral load.  If ommitted, no restrictions on
viral load are imposed.

=head2 has_available_aliquots

Matches samples with at least the given number (default 1) of aliquots
available.

=head2 tissue_type

Matches against the tissue type of the sample.

=head2 na_type 

Matches against the nucleic acid type of the sample.

=head2 derivation_protocol

Matches against the derivation protocol of the sample.

=head2 cohort

Matches against the cohorts of the patient of the sample.

=head2 project

Matches against the name of the projects of which the sample is part.

=head2 scientist

Matches against the full name of the scientist(s) I<assigned to> the sample.

=cut

sub _build_query_fields {
    return {
        freeform => {
            method => "search_freeform",
        },
        has_sequences => {
            method => "has_sequences",
        },
        has_quantifiable_viral_load => {
            method => "has_quantifiable_viral_load",
        },
        has_available_aliquots => {
            method => "has_available_aliquots",
        },
        tissue_type => {
            method => "tissue_type",
            facet  => {
                column  => "tissue_type",
                label   => "Tissue",
            },
        },
        na_type => {
            method => "na_type",
            facet  => {
                column  => "na_type",
                label   => "NA Type",
            },
        },
        derivation_protocol => {
            method => "derivation_protocol",
            facet  => {
                column  => "derivation_protocol",
                label   => "Derived by"
            },
        },
        cohort => {
            method => "cohort",
            facet  => {
                column  => \["unnest(cohorts)"],
                label   => "Cohort",
            },
        },

        # Project and scientist are faceted, but their query restrictions are
        # handled by the non-faceted assignment field definition below.
        project => {
            facet => {
                column  => \["jsonb_array_elements(assignments)->>'project'"],
                label   => "Project",
            },
        },
        scientist => {
            facet => {
                column  => \["jsonb_array_elements(assignments)->>'scientist'"],
                label   => "Scientist",
            },
        },
        assignment => {
            method => "assignment",
            values => sub {
                my $query = shift;
                my @projects   = map { +{ project   => $_ } } @{ $query->{project} };
                my @scientists = map { +{ scientist => $_ } } @{ $query->{scientist} };
                return unless @projects or @scientists;
                return \@projects   if @projects   and not @scientists;
                return \@scientists if @scientists and not @projects;
                return [
                    # Cross product
                    map {
                        my $p = $_;
                        map {
                            +{ %$_, %$p }
                        } @scientists
                    } @projects
                ];
            },
        }
    };
}

1;
