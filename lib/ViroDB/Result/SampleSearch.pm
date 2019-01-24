use utf8;
package ViroDB::Result::SampleSearch;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ViroDB::Result::SampleSearch

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

=head1 TABLE: C<viroserve.sample_search>

=cut

__PACKAGE__->table("viroserve.sample_search");

=head1 ACCESSORS

=head2 sample_id

  data_type: 'integer'
  is_nullable: 1

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 25

=head2 patient_name

  data_type: 'text'
  is_nullable: 1

=head2 tissue_type_id

  data_type: 'integer'
  is_nullable: 1

=head2 sample_type_id

  data_type: 'integer'
  is_nullable: 1

=head2 sample_type

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 visit_date

  data_type: 'date'
  is_nullable: 1

=head2 patient_id

  data_type: 'integer'
  is_nullable: 1

=head2 cohort_id

  data_type: 'smallint'
  is_nullable: 1

=head2 derivation_id

  data_type: 'integer'
  is_nullable: 1

=head2 viral_load

  data_type: 'numeric'
  is_nullable: 1

=head2 scientist_id

  data_type: 'integer'
  is_nullable: 1

=head2 scientist_name

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=cut

__PACKAGE__->add_columns(
  "sample_id",
  { data_type => "integer", is_nullable => 1 },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 25 },
  "patient_name",
  { data_type => "text", is_nullable => 1 },
  "tissue_type_id",
  { data_type => "integer", is_nullable => 1 },
  "sample_type_id",
  { data_type => "integer", is_nullable => 1 },
  "sample_type",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "visit_date",
  { data_type => "date", is_nullable => 1 },
  "patient_id",
  { data_type => "integer", is_nullable => 1 },
  "cohort_id",
  { data_type => "smallint", is_nullable => 1 },
  "derivation_id",
  { data_type => "integer", is_nullable => 1 },
  "viral_load",
  { data_type => "numeric", is_nullable => 1 },
  "scientist_id",
  { data_type => "integer", is_nullable => 1 },
  "scientist_name",
  { data_type => "varchar", is_nullable => 1, size => 45 },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2017-08-11 15:11:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:38otlghR98mW+lFkEv+7oA

__PACKAGE__->belongs_to(
  "sample",
  "ViroDB::Result::Sample",
  { sample_id => "sample_id" },
  {
    cascade_copy     => 0,
    cascade_delete   => 0,
  },
);

__PACKAGE__->belongs_to(
  "patient",
  "ViroDB::Result::Patient",
  { patient_id => "patient_id" },
  {
    cascade_copy     => 0,
    cascade_delete   => 0,
  },
);

__PACKAGE__->belongs_to(
  "tissue_type",
  "ViroDB::Result::TissueType",
  { tissue_type_id => "tissue_type_id" },
  {
    cascade_copy     => 0,
    cascade_delete   => 0,
  },
);

sub note_bodies {
    my $self = shift;
    return map {$_->body} $self->sample->notes;
}

sub TO_JSON {
    my $self = shift;

    return {
        id              => $self->sample_id,
        collection_date => ($self->visit_date ? $self->visit_date->strftime("%Y-%m-%d") : undef),
        subject         => $self->patient_name,
        tissue          => ($self->tissue_type ? $self->tissue_type->name : undef),
        notes           => (join ", ", $self->note_bodies),
        name            => $self->sample->to_string,
        sample_name     => $self->name,
        scientist       => $self->scientist_name,
        viral_load      => $self->viral_load,
    };
}

__PACKAGE__->meta->make_immutable;
1;
