use strict;
use warnings;
use 5.018;
use utf8;

package ViroDB::ResultSet::PrimerSearch;
use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'ViroDB::ResultSet';

with 'ViroDB::Helper::ResultSet::SearchArrayOverlaps';
with 'ViroDB::Helper::ResultSet::SearchFreeform', {
    text_fields => [qw[
        name
        sequence
        orientation
        organism
    ]],
    id_field    => "primer_id",
};

sub plausible_for {
    my ($self, $query) = @_;
    my $me    = $self->current_source_alias;
    my $where = qq{
                    regexp_replace(upper($me.name), '[^A-Z0-9]', '', 'g')
        LIKE '%' || regexp_replace(upper(?),        '[^A-Z0-9]', '', 'g') || '%'
    };

    return $self->search(\[ $where, $query ])
        ->order_by(\[ "length(?)::float / length($me.name) desc, $me.name asc", $query ]);
}

sub organism {
    my $self = shift;
    my $me   = $self->current_source_alias;
    return $self->search({ "$me.organism" => \@_ });
}

sub orientation {
    my $self = shift;
    my $me   = $self->current_source_alias;
    return $self->search({ "$me.orientation" => \@_ });
}

sub position {
    my $self = shift;
    return $self->search_array_overlaps( positions => @_ );
}


1;
