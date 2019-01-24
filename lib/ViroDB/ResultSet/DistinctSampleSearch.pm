use 5.010;
use strict;
use warnings;
use utf8;

package ViroDB::ResultSet::DistinctSampleSearch;
use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
use JSON::MaybeXS;
extends 'ViroDB::ResultSet';

# Necessary for DBIx::Class::ResultSet's weird constructor.  Refer to:
#   https://metacpan.org/pod/DBIx::Class::ResultSet#ResultSet-subclassing-with-Moose-and-similar-constructor-providers
sub BUILDARGS { $_[2] }

with 'ViroDB::Helper::ResultSet::SearchArrayOverlaps';
with 'ViroDB::Helper::ResultSet::SearchFreeform', {
    text_fields => [qw[ name patient ]],
    id_field    => "sample_id",
};

sub na_type {
    my $self = shift;
    my $me   = $self->current_source_alias;
    return $self->search({ "$me.na_type" => \@_ });
}

sub tissue_type {
    my $self = shift;
    my $me   = $self->current_source_alias;
    return $self->search({ "$me.tissue_type" => \@_ });
}

sub derivation_protocol {
    my $self = shift;
    my $me   = $self->current_source_alias;
    return $self->search({ "$me.derivation_protocol" => \@_ });
}

sub cohort {
    my $self = shift;
    return $self->search_array_overlaps( cohorts => @_ );
}

sub assignment {
    my $self = shift;
    my $me   = $self->current_source_alias;

    # The assignments column is a JSON array of objects with project and
    # scientist keys.  This method takes a list of hashrefs to match against
    # the JSON objects.  An indexed containment search (@>) is perfect but
    # the pattern-matching behaviour of it requires we wrap each condition
    # hashref into an array (and then convert the whole thing to JSON for Pg).
    # The literal SQL ends up looking like:
    #
    #   me.assignments @> '[{"scientist": "Thomas Sibley"}]'
    #
    return $self->search({
        "$me.assignments" => {
            '@>' => [ map { JSON->new->encode($_) } map { [$_] } @_ ],
        },
    });
}

sub has_sequences {
    my $self = shift;
    my $bool = shift // 1;
    my $op   = $bool ? "-bool" : "-not_bool";
    my $me   = $self->current_source_alias;
    return $self->search({ $op => "$me.has_sequences" });
}

sub has_quantifiable_viral_load {
    my $self = shift;
    my $bool = shift // 1;
    my $op   = $bool ? ">" : "=";
    my $me   = $self->current_source_alias;
    return $self->search({ "$me.viral_load" => { $op => 0 } });
}

sub has_available_aliquots {
    my $self = shift;
    my $n    = shift // 1;
    my $me   = $self->current_source_alias;
    return $self->search({ "$me.available_aliquots" => { ">=" => $n } });
}

1;
