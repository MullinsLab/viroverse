use strict;
use warnings;

package ViroDB::ResultSet::SequenceSearch;
use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'ViroDB::ResultSet';

# Necessary for DBIx::Class::ResultSet's weird constructor.  Refer to:
#   https://metacpan.org/pod/DBIx::Class::ResultSet#ResultSet-subclassing-with-Moose-and-similar-constructor-providers
sub BUILDARGS { $_[2] }

with 'ViroDB::Helper::ResultSet::SearchArrayOverlaps';
with 'ViroDB::Helper::ResultSet::SearchFreeform', {
    text_fields => [qw[ name pcr_name sample_name ]],
    id_pattern  => qr/^ (?<id>\d+) (?: \. (?<rev>\d+) )? $/x,
    id_field    => sub {
        my ($me, %match) = @_;
        return {
            "$me.na_sequence_id" => $match{id},
            ($match{rev}
                ? ("$me.na_sequence_revision" => $match{rev})
                : ()),
        };
    },
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

sub cohort {
    my $self = shift;
    return $self->search_array_overlaps( cohorts => @_ );
}

sub region {
    my $self = shift;
    return $self->search_array_overlaps( regions => @_ );
}

sub scientist {
    my $self = shift;
    my $me   = $self->current_source_alias;
    return $self->search({ "$me.scientist" => \@_ });
}

sub type {
    my $self = shift;
    my $me   = $self->current_source_alias;
    return $self->search({ "$me.type" => \@_ });
}

1;
