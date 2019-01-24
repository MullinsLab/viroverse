use utf8;
package ViroDB::Result::BoxPos;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ViroDB::Result::BoxPos

=cut

use strict;
use warnings;

=head1 BASE CLASS: L<ViroDB::Result>

=cut

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'ViroDB::Result';

=head1 TABLE: C<freezer.box_pos>

=cut

__PACKAGE__->table("freezer.box_pos");

=head1 ACCESSORS

=head2 box_pos_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'freezer.box_pos_box_pos_id_seq'

=head2 box_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 name

  data_type: 'char'
  is_nullable: 0
  size: 3

=head2 pos

  data_type: 'integer'
  is_nullable: 1

=head2 aliquot_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "box_pos_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "freezer.box_pos_box_pos_id_seq",
  },
  "box_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "name",
  { data_type => "char", is_nullable => 0, size => 3 },
  "pos",
  { data_type => "integer", is_nullable => 1 },
  "aliquot_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</box_pos_id>

=back

=cut

__PACKAGE__->set_primary_key("box_pos_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<box_pos_aliquot_id_idx>

=over 4

=item * L</aliquot_id>

=back

=cut

__PACKAGE__->add_unique_constraint("box_pos_aliquot_id_idx", ["aliquot_id"]);

=head1 RELATIONS

=head2 aliquot

Type: belongs_to

Related object: L<ViroDB::Result::Aliquot>

=cut

__PACKAGE__->belongs_to(
  "aliquot",
  "ViroDB::Result::Aliquot",
  { aliquot_id => "aliquot_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 box

Type: belongs_to

Related object: L<ViroDB::Result::Box>

=cut

__PACKAGE__->belongs_to(
  "box",
  "ViroDB::Result::Box",
  { box_id => "box_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2017-08-11 15:11:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ltS4uKS4eygGRz+WmnyyOA

=head1 METHODS

=head2 status

Describes the box position as one of the following:

=over 4

=item occupied

something shoud be in the postion

=item reserved

something has been removed but is slated to be returned

=item empty

something may be placed in the position

=back

=cut

sub status {
    my $self = shift;
    if ($self->aliquot) {
        if ($self->aliquot->possessing_scientist) {
            return "reserved";
        }
        return 'occupied';
    } else {
        return 'empty';
    }
}

sub location {
    my $self = shift;
    return $self->box->location . " / " . $self->name;
}

__PACKAGE__->meta->make_immutable;
1;
