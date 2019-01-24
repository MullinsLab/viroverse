use strict;
use warnings;
use utf8;
use 5.018;

package Viroverse::Import::CanPlaceAliquot;
use Moo::Role;
use ViroDB;
use Viroverse::Logger qw< :log >;
use namespace::clean;

requires 'track';

sub place_aliquot {
    my ($self, $row, $aliquot) = @_;

    if (length $row->{freezer} && length $row->{rack} && length $row->{box}) {
        my $box = ViroDB->instance->resultset("Box")->find_by_location(
            $row->{freezer}, $row->{rack}, $row->{box}
        ) or die "Box not found: $row->{freezer} / $row->{rack} / $row->{box}";
        my $pos = $box->next_empty_position or die "No empty spots in box";
        $pos->update({ aliquot => $aliquot });
        $self->track("Aliquot added to box");
    } elsif ($row->{freezer} || $row->{rack} || $row->{box}) {
        die "Incomplete freezer address; can't place aliquot.";
    } else {
        log_debug { "No freezer address given; not placing." };
    }
}

around 'suggested_column_for_key_pattern' => sub {
    my ($orig, $pkg, $key) = @_;
    return {
        rack => qr/tower|rack|cane/i,
    }->{$key} || $orig->($pkg, $key);
};


1;
