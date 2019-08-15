use strict;
use warnings;

package ViroDB::ResultSet::PacbioPool;
use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'ViroDB::ResultSet';

# Necessary for DBIx::Class::ResultSet's weird constructor.  Refer to:
#   https://metacpan.org/pod/DBIx::Class::ResultSet#ResultSet-subclassing-with-Moose-and-similar-constructor-providers
sub BUILDARGS { $_[2] }

with 'ViroDB::Helper::ResultSet::SearchFreeform', {
    text_fields => [qw[ sample_name pcr_nickname ]],
    id_field    => "pcr_product_id",
};

sub scientist {
    my $self = shift;
    my $me   = $self->current_source_alias;
    return $self->search({ "$me.scientist" => \@_ });
}

sub rt_primer {
    my $self = shift;
    my $me   = $self->current_source_alias;
    return $self->search({ "$me.rt_primer" => \@_ });
}

1;
