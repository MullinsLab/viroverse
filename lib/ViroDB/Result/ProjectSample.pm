use utf8;
package ViroDB::Result::ProjectSample;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ViroDB::Result::ProjectSample

=cut

use strict;
use warnings;

=head1 BASE CLASS: L<ViroDB::Result>

=cut

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'ViroDB::Result';

=head1 TABLE: C<viroserve.project_materials>

=cut

__PACKAGE__->table("viroserve.project_materials");

=head1 ACCESSORS

=head2 project_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 date_added

  data_type: 'date'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=head2 desig_scientist_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 sample_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "project_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "date_added",
  {
    data_type     => "date",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "desig_scientist_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "sample_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</project_id>

=item * L</sample_id>

=back

=cut

__PACKAGE__->set_primary_key("project_id", "sample_id");

=head1 RELATIONS

=head2 assigned_scientist

Type: belongs_to

Related object: L<ViroDB::Result::Scientist>

=cut

__PACKAGE__->belongs_to(
  "assigned_scientist",
  "ViroDB::Result::Scientist",
  { scientist_id => "desig_scientist_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 project

Type: belongs_to

Related object: L<ViroDB::Result::Project>

=cut

__PACKAGE__->belongs_to(
  "project",
  "ViroDB::Result::Project",
  { project_id => "project_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 sample

Type: belongs_to

Related object: L<ViroDB::Result::Sample>

=cut

__PACKAGE__->belongs_to(
  "sample",
  "ViroDB::Result::Sample",
  { sample_id => "sample_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2017-08-11 15:11:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:CG+syGIyDJ91BVpwVY9V/w

__PACKAGE__->belongs_to(
    "progress",
    "ViroDB::Result::ProjectSampleProgress",
    {
        'foreign.scientist_id' => 'self.desig_scientist_id',
        'foreign.sample_id'    => 'self.sample_id',
        'foreign.project_id'   => 'self.project_id'
    }
);


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
