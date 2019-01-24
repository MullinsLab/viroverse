use utf8;
package ViroDB::Result::Location;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ViroDB::Result::Location

=cut

use strict;
use warnings;

=head1 BASE CLASS: L<ViroDB::Result>

=cut

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'ViroDB::Result';

=head1 TABLE: C<viroserve.location>

=cut

__PACKAGE__->table("viroserve.location");

=head1 ACCESSORS

=head2 location_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'viroserve.location_location_id_seq'

=head2 city

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 country_abbr

  data_type: 'char'
  is_nullable: 1
  size: 2

=head2 site

  data_type: 'varchar'
  is_nullable: 1
  size: 25

=cut

__PACKAGE__->add_columns(
  "location_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "viroserve.location_location_id_seq",
  },
  "city",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "country_abbr",
  { data_type => "char", is_nullable => 1, size => 2 },
  "site",
  { data_type => "varchar", is_nullable => 1, size => 25 },
);

=head1 PRIMARY KEY

=over 4

=item * L</location_id>

=back

=cut

__PACKAGE__->set_primary_key("location_id");

=head1 RELATIONS

=head2 infections

Type: has_many

Related object: L<ViroDB::Result::Infection>

=cut

__PACKAGE__->has_many(
  "infections",
  "ViroDB::Result::Infection",
  { "foreign.location_id" => "self.location_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 patients

Type: has_many

Related object: L<ViroDB::Result::Patient>

=cut

__PACKAGE__->has_many(
  "patients",
  "ViroDB::Result::Patient",
  { "foreign.location_id" => "self.location_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2017-08-11 15:11:37
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:miCOBzezkF9nKfJKHvL6+g


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
