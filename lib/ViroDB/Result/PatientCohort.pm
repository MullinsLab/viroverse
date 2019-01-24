use utf8;
package ViroDB::Result::PatientCohort;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ViroDB::Result::PatientCohort

=cut

use strict;
use warnings;

=head1 BASE CLASS: L<ViroDB::Result>

=cut

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'ViroDB::Result';

=head1 TABLE: C<viroserve.patient_cohort>

=cut

__PACKAGE__->table("viroserve.patient_cohort");

=head1 ACCESSORS

=head2 patient_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 cohort_id

  data_type: 'smallint'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "patient_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "cohort_id",
  { data_type => "smallint", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</patient_id>

=item * L</cohort_id>

=back

=cut

__PACKAGE__->set_primary_key("patient_id", "cohort_id");

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


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2017-08-11 15:11:37
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:5zGcis12YnqOhr58kvP0nw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
