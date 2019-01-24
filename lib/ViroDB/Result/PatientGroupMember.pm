use utf8;
package ViroDB::Result::PatientGroupMember;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ViroDB::Result::PatientGroupMember

=cut

use strict;
use warnings;

=head1 BASE CLASS: L<ViroDB::Result>

=cut

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'ViroDB::Result';

=head1 TABLE: C<viroserve.patient_patient_group>

=cut

__PACKAGE__->table("viroserve.patient_patient_group");

=head1 ACCESSORS

=head2 patient_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 patient_group_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 alias

  data_type: 'varchar'
  is_nullable: 1
  size: 20

=cut

__PACKAGE__->add_columns(
  "patient_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "patient_group_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "alias",
  { data_type => "varchar", is_nullable => 1, size => 20 },
);

=head1 PRIMARY KEY

=over 4

=item * L</patient_id>

=item * L</patient_group_id>

=back

=cut

__PACKAGE__->set_primary_key("patient_id", "patient_group_id");

=head1 RELATIONS

=head2 group

Type: belongs_to

Related object: L<ViroDB::Result::PatientGroup>

=cut

__PACKAGE__->belongs_to(
  "group",
  "ViroDB::Result::PatientGroup",
  { patient_group_id => "patient_group_id" },
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


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2017-08-11 15:11:37
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:QnBDuBfy+zDPoG7/vOqCoQ

__PACKAGE__->has_many(
  "patient_summaries",
  "ViroDB::Result::CohortPatientSummary",
  { "foreign.patient_id" => "self.patient_id" }
);

__PACKAGE__->meta->make_immutable;
1;
