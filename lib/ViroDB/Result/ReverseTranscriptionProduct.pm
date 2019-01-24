use utf8;
package ViroDB::Result::ReverseTranscriptionProduct;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ViroDB::Result::ReverseTranscriptionProduct

=cut

use strict;
use warnings;

=head1 BASE CLASS: L<ViroDB::Result>

=cut

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'ViroDB::Result';

=head1 TABLE: C<viroserve.rt_product>

=cut

__PACKAGE__->table("viroserve.rt_product");

=head1 ACCESSORS

=head2 rt_product_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'viroserve.rt_product_rt_product_id_seq'

=head2 extraction_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

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

=head2 protocol_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 date_completed

  data_type: 'date'
  is_nullable: 1

=head2 vv_uid

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'viroserve.vv_uid'

=head2 notes

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 enzyme_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 rna_to_cdna_ratio

  data_type: 'numeric'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "rt_product_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "viroserve.rt_product_rt_product_id_seq",
  },
  "extraction_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
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
  "protocol_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "date_completed",
  { data_type => "date", is_nullable => 1 },
  "vv_uid",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "viroserve.vv_uid",
  },
  "notes",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "enzyme_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "rna_to_cdna_ratio",
  { data_type => "numeric", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</rt_product_id>

=back

=cut

__PACKAGE__->set_primary_key("rt_product_id");

=head1 RELATIONS

=head2 copy_numbers

Type: has_many

Related object: L<ViroDB::Result::CopyNumber>

=cut

__PACKAGE__->has_many(
  "copy_numbers",
  "ViroDB::Result::CopyNumber",
  { "foreign.rt_product_id" => "self.rt_product_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 extraction

Type: belongs_to

Related object: L<ViroDB::Result::Extraction>

=cut

__PACKAGE__->belongs_to(
  "extraction",
  "ViroDB::Result::Extraction",
  { extraction_id => "extraction_id" },
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
  { "foreign.rt_product_id" => "self.rt_product_id" },
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


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2018-01-19 14:42:10
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:PHuu4+CQwvpw7j/stdrLxw


with 'ViroDB::Role::HasCopyNumberSummary';
__PACKAGE__->meta->make_immutable;
1;
