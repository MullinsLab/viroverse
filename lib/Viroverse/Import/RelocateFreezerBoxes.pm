use strict;
use warnings;
use utf8;
use 5.018;

package Viroverse::Import::RelocateFreezerBoxes;
use Moo;
use Viroverse::Logger qw< :log :dlog >;
use Types::Standard -types;
use Viroverse::Types -types;
use Types::Common::String qw< SimpleStr NonEmptySimpleStr >;
use ViroDB;
use namespace::clean;

with 'Viroverse::Import';

=head1 DESCRIPTION

Identifies freezer boxes by name, and moves them to the listed freezer and rack from
wherever they are now.

=cut

__PACKAGE__->metadata->set_label("Freezer Box Locations");

has '+key_map' => (
    isa => Dict[
        freezer => NonEmptySimpleStr,
        rack    => NonEmptySimpleStr,
        shelf   => NonEmptySimpleStr,
        box     => NonEmptySimpleStr,
    ],
);

sub process_row {
    my ($self, $row) = @_;
    state $db = ViroDB->instance;

    my $freezer = $db->resultset("Freezer")->find({ name => $row->{freezer} })
        or die sprintf "Couldn't find a freezer named “%s”", $row->{freezer};

    my $rack = $freezer->racks->find({ name => $row->{rack} })
        or die sprintf "Couldn't find a rack named “%s”", $row->{rack};

    my @boxes = $db->resultset("Box")->search({ name => $row->{box} });
    die sprintf "Couldn't find a box named “%s”", $row->{box} unless @boxes;
    die sprintf "Found more than one box named “%s”", $row->{box} if @boxes > 1;
    my $box = $boxes[0];

    $box->update({
        rack => $rack,
        order_key => $row->{shelf},
    });

    log_info {[ "Moved %s to %s / %s", $box->name, $freezer->name, $rack->name ]};
    $self->track("Moved box");

}

1;
