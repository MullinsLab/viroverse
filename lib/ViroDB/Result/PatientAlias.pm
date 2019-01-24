use utf8;
package ViroDB::Result::PatientAlias;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ViroDB::Result::PatientAlias

=cut

use strict;
use warnings;

=head1 BASE CLASS: L<ViroDB::Result>

=cut

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'ViroDB::Result';

=head1 TABLE: C<viroserve.patient_alias>

=cut

__PACKAGE__->table("viroserve.patient_alias");

=head1 ACCESSORS

=head2 cohort_id

  data_type: 'smallint'
  is_foreign_key: 1
  is_nullable: 0

=head2 patient_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 external_patient_id

  data_type: 'varchar'
  is_nullable: 0
  size: 25

=head2 vv_uid

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 1
  sequence: 'viroserve.vv_uid'

=head2 type

  data_type: 'viroserve.patient_alias_type'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "cohort_id",
  { data_type => "smallint", is_foreign_key => 1, is_nullable => 0 },
  "patient_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "external_patient_id",
  { data_type => "varchar", is_nullable => 0, size => 25 },
  "vv_uid",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 1,
    sequence          => "viroserve.vv_uid",
  },
  "type",
  { data_type => "viroserve.patient_alias_type", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</cohort_id>

=item * L</patient_id>

=item * L</external_patient_id>

=back

=cut

__PACKAGE__->set_primary_key("cohort_id", "patient_id", "external_patient_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<unique_alias_within_cohort>

=over 4

=item * L</external_patient_id>

=item * L</cohort_id>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "unique_alias_within_cohort",
  ["external_patient_id", "cohort_id"],
);

=head1 RELATIONS

=head2 cohort

Type: belongs_to

Related object: L<ViroDB::Result::Cohort>

=cut

__PACKAGE__->belongs_to(
  "cohort",
  "ViroDB::Result::Cohort",
  { cohort_id => "cohort_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 patient

Type: belongs_to

Related object: L<ViroDB::Result::Patient>

=cut

__PACKAGE__->belongs_to(
  "patient",
  "ViroDB::Result::Patient",
  { patient_id => "patient_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2018-03-15 12:18:45
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:VdM3D0L1batmiWk7NZ2MkA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
