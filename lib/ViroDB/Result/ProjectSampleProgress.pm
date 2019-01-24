use utf8;
package ViroDB::Result::ProjectSampleProgress;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ViroDB::Result::ProjectSampleProgress

=cut

use strict;
use warnings;

=head1 BASE CLASS: L<ViroDB::Result>

=cut

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'ViroDB::Result';

=head1 TABLE: C<viroserve.project_material_scientist_progress>

=cut

__PACKAGE__->table("viroserve.project_material_scientist_progress");

=head1 ACCESSORS

=head2 project_id

  data_type: 'integer'
  is_nullable: 1

=head2 sample_id

  data_type: 'integer'
  is_nullable: 1

=head2 scientist_id

  data_type: 'integer'
  is_nullable: 1

=head2 has_extractions

  data_type: 'boolean'
  is_nullable: 1

=head2 has_rt_products

  data_type: 'boolean'
  is_nullable: 1

=head2 has_pcr_products

  data_type: 'boolean'
  is_nullable: 1

=head2 has_sequences

  data_type: 'boolean'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "project_id",
  { data_type => "integer", is_nullable => 1 },
  "sample_id",
  { data_type => "integer", is_nullable => 1 },
  "scientist_id",
  { data_type => "integer", is_nullable => 1 },
  "has_extractions",
  { data_type => "boolean", is_nullable => 1 },
  "has_rt_products",
  { data_type => "boolean", is_nullable => 1 },
  "has_pcr_products",
  { data_type => "boolean", is_nullable => 1 },
  "has_sequences",
  { data_type => "boolean", is_nullable => 1 },
);

=head1 UNIQUE CONSTRAINTS

=head2 C<project_material_scientist_progress_fk_idx>

=over 4

=item * L</project_id>

=item * L</sample_id>

=item * L</scientist_id>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "project_material_scientist_progress_fk_idx",
  ["project_id", "sample_id", "scientist_id"],
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2017-11-29 13:31:33
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ja+a4kr6zvp4VsZSy1jDsQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
