use strict;
use warnings;
use utf8;
use 5.018;

package ViroDB::ResultSet::Box;
use base 'ViroDB::ResultSet';

=head1 METHODS

=head2 find_by_location

Given freezer, rack, and box names as positional arguments, return the identified box.
Dies if more than one box is found.

=cut

sub find_by_location {
    my ($self, $freezer_name, $rack_name, $box_name) = @_;
    my $me = $self->current_source_alias;
    my $boxes = $self->search({
        "$me.name"     => $box_name,
        "rack.name"    => $rack_name,
        "freezer.name" => $freezer_name,
    }, { join => { rack => "freezer" } });
    if ($boxes->count > 1) {
        die "There's more than one box named $freezer_name / $rack_name / $box_name";
    }
    return $boxes->first;
}

sub create_with_box_positions {
    my ($self, $params) = @_;
    my $txn = $self->result_source->schema->txn_scope_guard;
    my $box = $self->create($params);
    $box->discard_changes;

    my $pos = 1;
    my $alpha = [undef, "A".."Z"];
    for my $row (1 .. $box->num_rows) {
        for my $column (1 .. $box->num_columns) {
            my $name = $row . $alpha->[$column];
            $box->add_to_box_positions({
                name   => $name,
                pos    => $pos,
            });
            $pos++;
        }
    }
    $txn->commit;
}

sub in_order {
    my $self = shift;
    return $self->search({}, { order_by => 'order_key' });
}

1;
