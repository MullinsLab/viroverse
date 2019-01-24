use utf8;
package ViroDB::Result::ScientistGroup;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ViroDB::Result::ScientistGroup

=cut

use strict;
use warnings;

=head1 BASE CLASS: L<ViroDB::Result>

=cut

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'ViroDB::Result';

=head1 TABLE: C<viroserve.scientist_group>

=cut

__PACKAGE__->table("viroserve.scientist_group");

=head1 ACCESSORS

=head2 scientist_group_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'viroserve.scientist_group_scientist_group_id_seq'

=head2 vv_uid

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 1
  sequence: 'viroserve.vv_uid'

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 creating_scientist_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 display

  data_type: 'boolean'
  is_nullable: 0

=head2 date_added

  data_type: 'date'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=cut

__PACKAGE__->add_columns(
  "scientist_group_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "viroserve.scientist_group_scientist_group_id_seq",
  },
  "vv_uid",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 1,
    sequence          => "viroserve.vv_uid",
  },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "creating_scientist_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "display",
  { data_type => "boolean", is_nullable => 0 },
  "date_added",
  {
    data_type     => "date",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</scientist_group_id>

=back

=cut

__PACKAGE__->set_primary_key("scientist_group_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<scientist_group_unique_name>

=over 4

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint("scientist_group_unique_name", ["name"]);

=head1 RELATIONS

=head2 creating_scientist

Type: belongs_to

Related object: L<ViroDB::Result::Scientist>

=cut

__PACKAGE__->belongs_to(
  "creating_scientist",
  "ViroDB::Result::Scientist",
  { scientist_id => "creating_scientist_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 memberships

Type: has_many

Related object: L<ViroDB::Result::ScientistGroupMember>

=cut

__PACKAGE__->has_many(
  "memberships",
  "ViroDB::Result::ScientistGroupMember",
  { "foreign.scientist_group_id" => "self.scientist_group_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2018-05-15 13:56:14
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:4UaDKXHsxyzd9d8xmtIlbA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
