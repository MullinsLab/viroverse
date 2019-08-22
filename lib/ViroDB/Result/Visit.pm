use utf8;
package ViroDB::Result::Visit;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ViroDB::Result::Visit

=cut

use strict;
use warnings;

=head1 BASE CLASS: L<ViroDB::Result>

=cut

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'ViroDB::Result';

=head1 TABLE: C<viroserve.visit>

=cut

__PACKAGE__->table("viroserve.visit");

=head1 ACCESSORS

=head2 visit_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'viroserve.visit_visit_id_seq'

=head2 patient_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 visit_date

  data_type: 'date'
  is_nullable: 1

=head2 visit_number

  data_type: 'varchar'
  is_nullable: 1
  size: 15

=head2 vv_uid

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'viroserve.vv_uid'

=head2 date_entered

  data_type: 'date'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=head2 is_deleted

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "visit_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "viroserve.visit_visit_id_seq",
  },
  "patient_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "visit_date",
  { data_type => "date", is_nullable => 1 },
  "visit_number",
  { data_type => "varchar", is_nullable => 1, size => 15 },
  "vv_uid",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "viroserve.vv_uid",
  },
  "date_entered",
  {
    data_type     => "date",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "is_deleted",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</visit_id>

=back

=cut

__PACKAGE__->set_primary_key("visit_id");

=head1 RELATIONS

=head2 categorical_lab_results

Type: has_many

Related object: L<ViroDB::Result::CategoricalLabResult>

=cut

__PACKAGE__->has_many(
  "categorical_lab_results",
  "ViroDB::Result::CategoricalLabResult",
  { "foreign.visit_id" => "self.visit_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 numeric_lab_results

Type: has_many

Related object: L<ViroDB::Result::NumericLabResult>

=cut

__PACKAGE__->has_many(
  "numeric_lab_results",
  "ViroDB::Result::NumericLabResult",
  { "foreign.visit_id" => "self.visit_id" },
  { cascade_copy => 0, cascade_delete => 0 },
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

=head2 samples

Type: has_many

Related object: L<ViroDB::Result::Sample>

=cut

__PACKAGE__->has_many(
  "samples",
  "ViroDB::Result::Sample",
  { "foreign.visit_id" => "self.visit_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2019-08-22 12:54:01
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:AyjMKQObEnM1DtbUSZGcoQ

=head2 best_viral_load

The C<viral_loads> view in the database will return at most one VL for
a given (patient, visit_date), viz., the "best" one per the PIC criteria.

=cut
__PACKAGE__->belongs_to(
    "best_viral_load",
    "ViroDB::Result::ViralLoad",
    { "foreign.patient_id" => "self.patient_id", "foreign.visit_date" => "self.visit_date" },
    { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->meta->make_immutable;
1;
