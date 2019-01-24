use utf8;
package ViroDB::Result::LegacyProtocol;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ViroDB::Result::LegacyProtocol

=cut

use strict;
use warnings;

=head1 BASE CLASS: L<ViroDB::Result>

=cut

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'ViroDB::Result';

=head1 TABLE: C<viroserve.protocol>

=cut

__PACKAGE__->table("viroserve.protocol");

=head1 ACCESSORS

=head2 protocol_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'viroserve.protocol_protocol_id_seq'

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 last_revision

  data_type: 'date'
  is_nullable: 1

=head2 source

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 protocol_type_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "protocol_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "viroserve.protocol_protocol_id_seq",
  },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "last_revision",
  { data_type => "date", is_nullable => 1 },
  "source",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "protocol_type_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</protocol_id>

=back

=cut

__PACKAGE__->set_primary_key("protocol_id");

=head1 RELATIONS

=head2 extractions

Type: has_many

Related object: L<ViroDB::Result::Extraction>

=cut

__PACKAGE__->has_many(
  "extractions",
  "ViroDB::Result::Extraction",
  { "foreign.protocol_id" => "self.protocol_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 gels

Type: has_many

Related object: L<ViroDB::Result::Gel>

=cut

__PACKAGE__->has_many(
  "gels",
  "ViroDB::Result::Gel",
  { "foreign.protocol_id" => "self.protocol_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 pcr_products

Type: has_many

Related object: L<ViroDB::Result::PolymeraseChainReactionProduct>

=cut

__PACKAGE__->has_many(
  "pcr_products",
  "ViroDB::Result::PolymeraseChainReactionProduct",
  { "foreign.protocol_id" => "self.protocol_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 protocol_type

Type: belongs_to

Related object: L<ViroDB::Result::LegacyProtocolType>

=cut

__PACKAGE__->belongs_to(
  "protocol_type",
  "ViroDB::Result::LegacyProtocolType",
  { protocol_type_id => "protocol_type_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 rt_products

Type: has_many

Related object: L<ViroDB::Result::ReverseTranscriptionProduct>

=cut

__PACKAGE__->has_many(
  "rt_products",
  "ViroDB::Result::ReverseTranscriptionProduct",
  { "foreign.protocol_id" => "self.protocol_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2018-01-26 10:45:22
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:wHN0LbwKVIS3UCrfikAV4g


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
