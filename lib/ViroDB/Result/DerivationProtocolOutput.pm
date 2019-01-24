use utf8;
package ViroDB::Result::DerivationProtocolOutput;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ViroDB::Result::DerivationProtocolOutput

=cut

use strict;
use warnings;

=head1 BASE CLASS: L<ViroDB::Result>

=cut

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'ViroDB::Result';

=head1 TABLE: C<delta.protocol_output>

=cut

__PACKAGE__->table("delta.protocol_output");

=head1 ACCESSORS

=head2 protocol_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 tissue_type_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "protocol_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "tissue_type_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
);

=head1 UNIQUE CONSTRAINTS

=head2 C<protocol_output_protocol_id_tissue_type_id_key>

=over 4

=item * L</protocol_id>

=item * L</tissue_type_id>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "protocol_output_protocol_id_tissue_type_id_key",
  ["protocol_id", "tissue_type_id"],
);

=head1 RELATIONS

=head2 protocol

Type: belongs_to

Related object: L<ViroDB::Result::DerivationProtocol>

=cut

__PACKAGE__->belongs_to(
  "protocol",
  "ViroDB::Result::DerivationProtocol",
  { protocol_id => "protocol_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 tissue_type

Type: belongs_to

Related object: L<ViroDB::Result::TissueType>

=cut

__PACKAGE__->belongs_to(
  "tissue_type",
  "ViroDB::Result::TissueType",
  { tissue_type_id => "tissue_type_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2017-08-11 15:11:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:o9ynuil3A32BggRE5npASg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
