use utf8;
package ViroDB::Result::Unit;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ViroDB::Result::Unit

=cut

use strict;
use warnings;

=head1 BASE CLASS: L<ViroDB::Result>

=cut

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'ViroDB::Result';

=head1 TABLE: C<viroserve.unit>

=cut

__PACKAGE__->table("viroserve.unit");

=head1 ACCESSORS

=head2 unit_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'viroserve.unit_unit_id_seq'

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 45

=cut

__PACKAGE__->add_columns(
  "unit_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "viroserve.unit_unit_id_seq",
  },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 45 },
);

=head1 PRIMARY KEY

=over 4

=item * L</unit_id>

=back

=cut

__PACKAGE__->set_primary_key("unit_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<unit_name_key>

=over 4

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint("unit_name_key", ["name"]);

=head1 RELATIONS

=head2 aliquots

Type: has_many

Related object: L<ViroDB::Result::Aliquot>

=cut

__PACKAGE__->has_many(
  "aliquots",
  "ViroDB::Result::Aliquot",
  { "foreign.unit_id" => "self.unit_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 extraction_concentration_units

Type: has_many

Related object: L<ViroDB::Result::Extraction>

=cut

__PACKAGE__->has_many(
  "extraction_concentration_units",
  "ViroDB::Result::Extraction",
  { "foreign.concentration_unit_id" => "self.unit_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 extraction_eluted_vol_units

Type: has_many

Related object: L<ViroDB::Result::Extraction>

=cut

__PACKAGE__->has_many(
  "extraction_eluted_vol_units",
  "ViroDB::Result::Extraction",
  { "foreign.eluted_vol_unit_id" => "self.unit_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 extraction_units

Type: has_many

Related object: L<ViroDB::Result::Extraction>

=cut

__PACKAGE__->has_many(
  "extraction_units",
  "ViroDB::Result::Extraction",
  { "foreign.unit_id" => "self.unit_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 numeric_lab_result_types

Type: has_many

Related object: L<ViroDB::Result::NumericLabResultType>

=cut

__PACKAGE__->has_many(
  "numeric_lab_result_types",
  "ViroDB::Result::NumericLabResultType",
  { "foreign.unit_id" => "self.unit_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 pcr_templates

Type: has_many

Related object: L<ViroDB::Result::PolymeraseChainReactionTemplate>

=cut

__PACKAGE__->has_many(
  "pcr_templates",
  "ViroDB::Result::PolymeraseChainReactionTemplate",
  { "foreign.unit_id" => "self.unit_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2017-09-07 13:34:53
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:/VSXaGhLGnqS95cxWDYwOw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
