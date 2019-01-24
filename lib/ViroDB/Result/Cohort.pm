use utf8;
package ViroDB::Result::Cohort;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ViroDB::Result::Cohort

=cut

use strict;
use warnings;

=head1 BASE CLASS: L<ViroDB::Result>

=cut

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'ViroDB::Result';

=head1 TABLE: C<viroserve.cohort>

=cut

__PACKAGE__->table("viroserve.cohort");

=head1 ACCESSORS

=head2 cohort_id

  data_type: 'smallint'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'viroserve.cohort_cohort_id_seq'

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 25

=head2 abbr

  data_type: 'char'
  is_nullable: 1
  size: 2

=head2 vv_uid

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'viroserve.vv_uid'

=cut

__PACKAGE__->add_columns(
  "cohort_id",
  {
    data_type         => "smallint",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "viroserve.cohort_cohort_id_seq",
  },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 25 },
  "abbr",
  { data_type => "char", is_nullable => 1, size => 2 },
  "vv_uid",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "viroserve.vv_uid",
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</cohort_id>

=back

=cut

__PACKAGE__->set_primary_key("cohort_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<cohort_name_key>

=over 4

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint("cohort_name_key", ["name"]);

=head1 RELATIONS

=head2 patient_aliases

Type: has_many

Related object: L<ViroDB::Result::PatientAlias>

=cut

__PACKAGE__->has_many(
  "patient_aliases",
  "ViroDB::Result::PatientAlias",
  { "foreign.cohort_id" => "self.cohort_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 patient_cohorts

Type: has_many

Related object: L<ViroDB::Result::PatientCohort>

=cut

__PACKAGE__->has_many(
  "patient_cohorts",
  "ViroDB::Result::PatientCohort",
  { "foreign.cohort_id" => "self.cohort_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 patients

Type: many_to_many

Composing rels: L</patient_cohorts> -> patient

=cut

__PACKAGE__->many_to_many("patients", "patient_cohorts", "patient");


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2017-08-11 15:11:37
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:0FNHvSz5LYlck/d4apdDJA

=head2 patient_summaries

Type: has_many

Related object: L<ViroDB::Result::CohortPatientSummary>

=cut

__PACKAGE__->has_many(
  "patient_summaries",
  "ViroDB::Result::CohortPatientSummary",
  { "foreign.cohort_id" => "self.cohort_id" },
  { order_by => "name", cascade_copy => 0, cascade_delete => 0 },
);

=head2 find_patient_by_alias

Returns the patient in this cohort that has the given primary alias

=cut

sub find_patient_by_alias {
    my ($self, $external_patient_id) = @_;
    my $alias = $self->search_related('patient_aliases',
        { external_patient_id => $external_patient_id, "type" => "primary" },
    )->single;
    return undef unless $alias;
    return $alias->patient;
}

__PACKAGE__->meta->make_immutable;
1;
