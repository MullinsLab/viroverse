use strict;
use warnings;
use utf8;
use 5.018;

package ViroDB::ResultSet::Gel;
use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'ViroDB::ResultSet';

with 'ViroDB::Helper::ResultSet::SearchFreeform', {
    text_fields => [qw[
        name
        notes
    ]],
    id_field    => "gel_id",
};

sub scientist {
    my $self = shift;
    my $me   = $self->current_source_alias;
    return $self->search({ "scientist.name" => \@_ }, { join => "scientist" });
}

1;
