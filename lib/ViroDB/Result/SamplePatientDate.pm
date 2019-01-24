use utf8;
package ViroDB::Result::SamplePatientDate;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ViroDB::Result::SamplePatientDate

=cut

use strict;
use warnings;

=head1 BASE CLASS: L<ViroDB::Result>

=cut

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'ViroDB::Result';
__PACKAGE__->table_class("DBIx::Class::ResultSource::View");

=head1 TABLE: C<viroserve.sample_patient_date>

=cut

__PACKAGE__->table("viroserve.sample_patient_date");

=head1 ACCESSORS

=head2 sample_id

  data_type: 'integer'
  is_nullable: 1

=head2 patient_id

  data_type: 'integer'
  is_nullable: 1

=head2 sample_date

  data_type: 'date'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "sample_id",
  { data_type => "integer", is_nullable => 1 },
  "patient_id",
  { data_type => "integer", is_nullable => 1 },
  "sample_date",
  { data_type => "date", is_nullable => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2018-02-02 13:54:26
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:TkglpJf/OfT7o4TWNj7SoQ

# This is a view, so FK and nullable information isn't introspectable by the
# model dumper.
__PACKAGE__->add_columns(
    "+sample_id"  => { is_foreign_key => 1, is_nullable => 0 },
    "+patient_id" => { is_foreign_key => 1, is_nullable => 0 },
);

__PACKAGE__->add_unique_constraint("sample_patient_date_sample_id_key", ["sample_id"]);

=head2 sample

Type: belongs_to

Related object: L<ViroDB::Result::Sample>

=cut

__PACKAGE__->belongs_to(
  "sample",
  "ViroDB::Result::Sample",
  { sample_id => "sample_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 patient

Type: belongs_to

Related object: L<ViroDB::Result::Patient>

=cut

__PACKAGE__->belongs_to(
  "patient",
  "ViroDB::Result::Patient",
  { patient_id => "patient_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

__PACKAGE__->meta->make_immutable;
1;
