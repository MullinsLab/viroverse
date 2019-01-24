use utf8;
package ViroDB::Result::Infection;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ViroDB::Result::Infection

=cut

use strict;
use warnings;

=head1 BASE CLASS: L<ViroDB::Result>

=cut

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'ViroDB::Result';

=head1 TABLE: C<viroserve.infection>

=cut

__PACKAGE__->table("viroserve.infection");

=head1 ACCESSORS

=head2 infection_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'viroserve.infection_infection_id_seq'

=head2 location_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 patient_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 infection_earliest

  data_type: 'date'
  is_nullable: 1

=head2 infection_latest

  data_type: 'date'
  is_nullable: 1

=head2 seroconv_earliest

  data_type: 'date'
  is_nullable: 1

=head2 seroconv_latest

  data_type: 'date'
  is_nullable: 1

=head2 symptom_earliest

  data_type: 'date'
  is_nullable: 1

=head2 symptom_latest

  data_type: 'date'
  is_nullable: 1

=head2 note

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 estimated_date

  data_type: 'date'
  is_nullable: 1

Best estimated or calculated infection date, to be preferentially used in queries

=cut

__PACKAGE__->add_columns(
  "infection_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "viroserve.infection_infection_id_seq",
  },
  "location_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "patient_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "infection_earliest",
  { data_type => "date", is_nullable => 1 },
  "infection_latest",
  { data_type => "date", is_nullable => 1 },
  "seroconv_earliest",
  { data_type => "date", is_nullable => 1 },
  "seroconv_latest",
  { data_type => "date", is_nullable => 1 },
  "symptom_earliest",
  { data_type => "date", is_nullable => 1 },
  "symptom_latest",
  { data_type => "date", is_nullable => 1 },
  "note",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "estimated_date",
  { data_type => "date", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</infection_id>

=back

=cut

__PACKAGE__->set_primary_key("infection_id");

=head1 RELATIONS

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
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:kGxg8J7HPTrPn6HAgdPHbw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
