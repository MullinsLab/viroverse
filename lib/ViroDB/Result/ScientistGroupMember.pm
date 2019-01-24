use utf8;
package ViroDB::Result::ScientistGroupMember;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ViroDB::Result::ScientistGroupMember

=cut

use strict;
use warnings;

=head1 BASE CLASS: L<ViroDB::Result>

=cut

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'ViroDB::Result';

=head1 TABLE: C<viroserve.scientist_scientist_group>

=cut

__PACKAGE__->table("viroserve.scientist_scientist_group");

=head1 ACCESSORS

=head2 scientist_group_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 scientist_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 date_added

  data_type: 'date'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=head2 creating_scientist_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "scientist_group_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "scientist_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "date_added",
  {
    data_type     => "date",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "creating_scientist_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
);

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

=head2 group

Type: belongs_to

Related object: L<ViroDB::Result::ScientistGroup>

=cut

__PACKAGE__->belongs_to(
  "group",
  "ViroDB::Result::ScientistGroup",
  { scientist_group_id => "scientist_group_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 scientist

Type: belongs_to

Related object: L<ViroDB::Result::Scientist>

=cut

__PACKAGE__->belongs_to(
  "scientist",
  "ViroDB::Result::Scientist",
  { scientist_id => "scientist_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2017-08-11 15:11:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:l4g0Q7nxAhXSBP8fO/iquA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
