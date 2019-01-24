use utf8;
package ViroDB::Result::PatientGroup;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ViroDB::Result::PatientGroup

=cut

use strict;
use warnings;

=head1 BASE CLASS: L<ViroDB::Result>

=cut

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'ViroDB::Result';

=head1 TABLE: C<viroserve.patient_group>

=cut

__PACKAGE__->table("viroserve.patient_group");

=head1 ACCESSORS

=head2 patient_group_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'viroserve.patient_group_patient_group_id_seq'

=head2 scientist_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 created

  data_type: 'date'
  is_nullable: 1

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=cut

__PACKAGE__->add_columns(
  "patient_group_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "viroserve.patient_group_patient_group_id_seq",
  },
  "scientist_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "created",
  { data_type => "date", is_nullable => 1 },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 45 },
);

=head1 PRIMARY KEY

=over 4

=item * L</patient_group_id>

=back

=cut

__PACKAGE__->set_primary_key("patient_group_id");

=head1 RELATIONS

=head2 memberships

Type: has_many

Related object: L<ViroDB::Result::PatientGroupMember>

=cut

__PACKAGE__->has_many(
  "memberships",
  "ViroDB::Result::PatientGroupMember",
  { "foreign.patient_group_id" => "self.patient_group_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 scientist

Type: belongs_to

Related object: L<ViroDB::Result::Scientist>

=cut

__PACKAGE__->belongs_to(
  "scientist",
  "ViroDB::Result::Scientist",
  { scientist_id => "scientist_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2017-08-11 15:11:37
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:McrHVjsYQIEOasWZqNGlWQ

__PACKAGE__->many_to_many(
  "patient_summaries",
  "memberships",
  "patient_summaries",
);

__PACKAGE__->meta->make_immutable;
1;
