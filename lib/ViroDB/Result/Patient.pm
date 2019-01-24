use utf8;
package ViroDB::Result::Patient;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ViroDB::Result::Patient

=cut

use strict;
use warnings;

=head1 BASE CLASS: L<ViroDB::Result>

=cut

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'ViroDB::Result';

=head1 TABLE: C<viroserve.patient>

=cut

__PACKAGE__->table("viroserve.patient");

=head1 ACCESSORS

=head2 patient_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'viroserve.patient_patient_id_seq'

=head2 location_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 gender

  data_type: 'viroserve.gender_code'
  is_nullable: 1

=head2 birth

  data_type: 'date'
  is_nullable: 1

=head2 death

  data_type: 'date'
  is_nullable: 1

=head2 symptom_onset

  data_type: 'date'
  is_nullable: 1

=head2 multiply_infected

  data_type: 'boolean'
  is_nullable: 1

=head2 vv_uid

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 1
  sequence: 'viroserve.vv_uid'

=head2 date_added

  data_type: 'date'
  default_value: current_timestamp
  is_nullable: 1
  original: {default_value => \"now()"}

=cut

__PACKAGE__->add_columns(
  "patient_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "viroserve.patient_patient_id_seq",
  },
  "location_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "gender",
  { data_type => "viroserve.gender_code", is_nullable => 1 },
  "birth",
  { data_type => "date", is_nullable => 1 },
  "death",
  { data_type => "date", is_nullable => 1 },
  "symptom_onset",
  { data_type => "date", is_nullable => 1 },
  "multiply_infected",
  { data_type => "boolean", is_nullable => 1 },
  "vv_uid",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 1,
    sequence          => "viroserve.vv_uid",
  },
  "date_added",
  {
    data_type     => "date",
    default_value => \"current_timestamp",
    is_nullable   => 1,
    original      => { default_value => \"now()" },
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</patient_id>

=back

=cut

__PACKAGE__->set_primary_key("patient_id");

=head1 RELATIONS

=head2 group_memberships

Type: has_many

Related object: L<ViroDB::Result::PatientGroupMember>

=cut

__PACKAGE__->has_many(
  "group_memberships",
  "ViroDB::Result::PatientGroupMember",
  { "foreign.patient_id" => "self.patient_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 infections

Type: has_many

Related object: L<ViroDB::Result::Infection>

=cut

__PACKAGE__->has_many(
  "infections",
  "ViroDB::Result::Infection",
  { "foreign.patient_id" => "self.patient_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 location

Type: belongs_to

Related object: L<ViroDB::Result::Location>

=cut

__PACKAGE__->belongs_to(
  "location",
  "ViroDB::Result::Location",
  { location_id => "location_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 patient_aliases

Type: has_many

Related object: L<ViroDB::Result::PatientAlias>

=cut

__PACKAGE__->has_many(
  "patient_aliases",
  "ViroDB::Result::PatientAlias",
  { "foreign.patient_id" => "self.patient_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 patient_cohorts

Type: has_many

Related object: L<ViroDB::Result::PatientCohort>

=cut

__PACKAGE__->has_many(
  "patient_cohorts",
  "ViroDB::Result::PatientCohort",
  { "foreign.patient_id" => "self.patient_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 patient_medications

Type: has_many

Related object: L<ViroDB::Result::PatientMedication>

=cut

__PACKAGE__->has_many(
  "patient_medications",
  "ViroDB::Result::PatientMedication",
  { "foreign.patient_id" => "self.patient_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 visits

Type: has_many

Related object: L<ViroDB::Result::Visit>

=cut

__PACKAGE__->has_many(
  "visits",
  "ViroDB::Result::Visit",
  { "foreign.patient_id" => "self.patient_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 cohorts

Type: many_to_many

Composing rels: L</patient_cohorts> -> cohort

=cut

__PACKAGE__->many_to_many("cohorts", "patient_cohorts", "cohort");


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2017-11-28 11:25:20
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:kTccTyjv/k5jiyVsDcPeig

__PACKAGE__->has_many("primary_aliases",
    "ViroDB::Result::PatientAlias",
    sub {
        my $args = shift;
        return {
            "$args->{foreign_alias}.patient_id" => { -ident => "$args->{self_alias}.patient_id" },
            "$args->{foreign_alias}.type" => "primary",
        }
    },
    { order_by => { -asc => 'cohort_id' }, },
);

__PACKAGE__->has_many("publication_aliases",
    "ViroDB::Result::PatientAlias",
    sub {
        my $args = shift;
        return {
            "$args->{foreign_alias}.patient_id" => { -ident => "$args->{self_alias}.patient_id" },
            "$args->{foreign_alias}.type" => "publication",
        }
    },
    { order_by => { -asc => 'cohort_id' }, },
);

__PACKAGE__->has_many("other_aliases",
    "ViroDB::Result::PatientAlias",
    sub {
        my $args = shift;
        return {
            "$args->{foreign_alias}.patient_id" => { -ident => "$args->{self_alias}.patient_id" },
            "$args->{foreign_alias}.type" => "alias",
        }
    },
    { order_by => { -asc => 'cohort_id' }, },
);

__PACKAGE__->has_many("viral_loads",
    "ViroDB::Result::ViralLoad",
    { "foreign.patient_id" => "self.patient_id" },
    { order_by => "visit_date", cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many("cell_counts",
    "ViroDB::Result::CellCount",
    { "foreign.patient_id" => "self.patient_id" },
    { order_by => "visit_date", cascade_copy => 0, cascade_delete => 0 },
);


=head1 METHODS

=head2 samples

Returns a L<ViroDB::ResultSet::Sample> limited to this patient.

Note that this isn't backed by a real L<DBIx::Class::Relationship> in order to
avoid unnecessary joins.

=cut

sub samples {
    my $self = shift;
    return $self->result_source->schema->resultset("Sample")->search_rs(
        { "patient_and_date.patient_id" => $self->patient_id },
        { join => "patient_and_date" }
    );
}


=head2 name

Returns this patient's primary alias (cohort name + cohort-specific ID),
matching the logic originally provided by the C<patient_name> SQL function.

=cut

sub name {
    my $self  = shift;
    my $alias = $self->primary_alias;
    return "Unnamed patient" unless defined $alias;
    my $cohort = $alias->cohort;
    return $cohort->name . ' ' . $alias->external_patient_id;
}

sub publication_name {
    my $self = shift;
    my $pub_alias = $self->publication_aliases->first;
    return undef unless $pub_alias;
    return $pub_alias->cohort->name . " " . $pub_alias->external_patient_id;
}

sub primary_alias {
    my $self = shift;
    return $self->primary_aliases->first;
}

sub aliases {
    my $self = shift;
    return map { $_->external_patient_id } $self->patient_aliases->all;
}

__PACKAGE__->meta->make_immutable;
1;
