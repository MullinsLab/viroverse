use utf8;
package ViroDB::Result::PolymeraseChainReactionProduct;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ViroDB::Result::PolymeraseChainReactionProduct

=cut

use strict;
use warnings;

=head1 BASE CLASS: L<ViroDB::Result>

=cut

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'ViroDB::Result';

=head1 TABLE: C<viroserve.pcr_product>

=cut

__PACKAGE__->table("viroserve.pcr_product");

=head1 ACCESSORS

=head2 pcr_product_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'viroserve.pcr_product_pcr_product_id_seq'

=head2 scientist_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 date_entered

  data_type: 'date'
  default_value: current_timestamp
  is_nullable: 1
  original: {default_value => \"now()"}

=head2 purified

  data_type: 'boolean'
  is_nullable: 1

=head2 notes

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 date_completed

  data_type: 'date'
  is_nullable: 1

=head2 round

  data_type: 'integer'
  is_nullable: 1

=head2 successful

  data_type: 'boolean'
  is_nullable: 1

=head2 replicate

  data_type: 'integer'
  is_nullable: 1

=head2 enzyme_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 hot_start

  data_type: 'boolean'
  is_nullable: 1

=head2 protocol_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 vv_uid

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'viroserve.vv_uid'

=head2 genome_portion

  data_type: 'smallint'
  is_nullable: 1

=head2 pcr_template_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 pcr_pool_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 reamp_round

  data_type: 'integer'
  is_nullable: 1

=head2 endpoint_dilution

  data_type: 'boolean'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "pcr_product_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "viroserve.pcr_product_pcr_product_id_seq",
  },
  "scientist_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "date_entered",
  {
    data_type     => "date",
    default_value => \"current_timestamp",
    is_nullable   => 1,
    original      => { default_value => \"now()" },
  },
  "purified",
  { data_type => "boolean", is_nullable => 1 },
  "notes",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "date_completed",
  { data_type => "date", is_nullable => 1 },
  "round",
  { data_type => "integer", is_nullable => 1 },
  "successful",
  { data_type => "boolean", is_nullable => 1 },
  "replicate",
  { data_type => "integer", is_nullable => 1 },
  "enzyme_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "hot_start",
  { data_type => "boolean", is_nullable => 1 },
  "protocol_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "vv_uid",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "viroserve.vv_uid",
  },
  "genome_portion",
  { data_type => "smallint", is_nullable => 1 },
  "pcr_template_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "pcr_pool_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "reamp_round",
  { data_type => "integer", is_nullable => 1 },
  "endpoint_dilution",
  { data_type => "boolean", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</pcr_product_id>

=back

=cut

__PACKAGE__->set_primary_key("pcr_product_id");

=head1 RELATIONS

=head2 enzyme

Type: belongs_to

Related object: L<ViroDB::Result::Enzyme>

=cut

__PACKAGE__->belongs_to(
  "enzyme",
  "ViroDB::Result::Enzyme",
  { enzyme_id => "enzyme_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 gel_lanes

Type: has_many

Related object: L<ViroDB::Result::GelLane>

=cut

__PACKAGE__->has_many(
  "gel_lanes",
  "ViroDB::Result::GelLane",
  { "foreign.pcr_product_id" => "self.pcr_product_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 na_sequences

Type: has_many

Related object: L<ViroDB::Result::NucleicAcidSequence>

=cut

__PACKAGE__->has_many(
  "na_sequences",
  "ViroDB::Result::NucleicAcidSequence",
  { "foreign.pcr_product_id" => "self.pcr_product_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 pcr_template

Type: belongs_to

Related object: L<ViroDB::Result::PolymeraseChainReactionTemplate>

=cut

__PACKAGE__->belongs_to(
  "pcr_template",
  "ViroDB::Result::PolymeraseChainReactionTemplate",
  { pcr_template_id => "pcr_template_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 pcr_templates

Type: has_many

Related object: L<ViroDB::Result::PolymeraseChainReactionTemplate>

=cut

__PACKAGE__->has_many(
  "pcr_templates",
  "ViroDB::Result::PolymeraseChainReactionTemplate",
  { "foreign.pcr_product_id" => "self.pcr_product_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 primer_assignments

Type: has_many

Related object: L<ViroDB::Result::PolymeraseChainReactionProductPrimer>

=cut

__PACKAGE__->has_many(
  "primer_assignments",
  "ViroDB::Result::PolymeraseChainReactionProductPrimer",
  { "foreign.pcr_product_id" => "self.pcr_product_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 protocol

Type: belongs_to

Related object: L<ViroDB::Result::LegacyProtocol>

=cut

__PACKAGE__->belongs_to(
  "protocol",
  "ViroDB::Result::LegacyProtocol",
  { protocol_id => "protocol_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 scientist

Type: belongs_to

Related object: L<ViroDB::Result::Scientist>

=cut

__PACKAGE__->belongs_to(
  "scientist",
  "ViroDB::Result::Scientist",
  { scientist_id => "scientist_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 primers

Type: many_to_many

Composing rels: L</primer_assignments> -> primer

=cut

__PACKAGE__->many_to_many("primers", "primer_assignments", "primer");


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2019-05-06 17:19:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:eNrEKXJo+FfBjj88cUpKuA

use 5.018;
use warnings;
use strict;

sub input_product { return $_[0]->pcr_template; }
with "Viroverse::Model::Role::MolecularProduct";

__PACKAGE__->meta->make_immutable;
1;
