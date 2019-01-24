use utf8;
package ViroDB::Result::Freezer;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ViroDB::Result::Freezer

=cut

use strict;
use warnings;

=head1 BASE CLASS: L<ViroDB::Result>

=cut

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'ViroDB::Result';

=head1 TABLE: C<freezer.freezer>

=cut

__PACKAGE__->table("freezer.freezer");

=head1 ACCESSORS

=head2 freezer_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'freezer.freezer_freezer_id_seq'

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 owning_scientist_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 creating_scientist_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 description

  data_type: 'text'
  is_nullable: 1

=head2 location

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 upright_chest

  data_type: 'char'
  is_nullable: 1
  size: 1

=head2 cane_alpha_int

  data_type: 'char'
  default_value: 'a'
  is_nullable: 1
  size: 1

=head2 vv_uid

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'viroserve.vv_uid'

=head2 is_offsite

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "freezer_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "freezer.freezer_freezer_id_seq",
  },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "owning_scientist_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "creating_scientist_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "description",
  { data_type => "text", is_nullable => 1 },
  "location",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "upright_chest",
  { data_type => "char", is_nullable => 1, size => 1 },
  "cane_alpha_int",
  { data_type => "char", default_value => "a", is_nullable => 1, size => 1 },
  "vv_uid",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "viroserve.vv_uid",
  },
  "is_offsite",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</freezer_id>

=back

=cut

__PACKAGE__->set_primary_key("freezer_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<frezer_name_unique>

=over 4

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint("frezer_name_unique", ["name"]);

=head1 RELATIONS

=head2 creating_scientist

Type: belongs_to

Related object: L<ViroDB::Result::Scientist>

=cut

__PACKAGE__->belongs_to(
  "creating_scientist",
  "ViroDB::Result::Scientist",
  { scientist_id => "creating_scientist_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 owning_scientist

Type: belongs_to

Related object: L<ViroDB::Result::Scientist>

=cut

__PACKAGE__->belongs_to(
  "owning_scientist",
  "ViroDB::Result::Scientist",
  { scientist_id => "owning_scientist_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 racks

Type: has_many

Related object: L<ViroDB::Result::Rack>

=cut

__PACKAGE__->has_many(
  "racks",
  "ViroDB::Result::Rack",
  { "foreign.freezer_id" => "self.freezer_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2017-08-11 15:11:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:PWz560NXkA+ZqPZRy7V95g

__PACKAGE__->meta->make_immutable;
1;
