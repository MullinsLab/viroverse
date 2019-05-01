use utf8;
package ViroDB::Result::DerivationProtocol;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ViroDB::Result::DerivationProtocol

=cut

use strict;
use warnings;

=head1 BASE CLASS: L<ViroDB::Result>

=cut

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'ViroDB::Result';

=head1 TABLE: C<viroserve.derivation_protocol>

=cut

__PACKAGE__->table("viroserve.derivation_protocol");

=head1 ACCESSORS

=head2 derivation_protocol_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'viroserve.derivation_protocol_derivation_protocol_id_seq'

=head2 name

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "derivation_protocol_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "viroserve.derivation_protocol_derivation_protocol_id_seq",
  },
  "name",
  { data_type => "text", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</derivation_protocol_id>

=back

=cut

__PACKAGE__->set_primary_key("derivation_protocol_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<derivation_protocol_name_key>

=over 4

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint("derivation_protocol_name_key", ["name"]);

=head1 RELATIONS

=head2 derivations

Type: has_many

Related object: L<ViroDB::Result::Derivation>

=cut

__PACKAGE__->has_many(
  "derivations",
  "ViroDB::Result::Derivation",
  {
    "foreign.derivation_protocol_id" => "self.derivation_protocol_id",
  },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 protocol_outputs

Type: has_many

Related object: L<ViroDB::Result::DerivationProtocolOutput>

=cut

__PACKAGE__->has_many(
  "protocol_outputs",
  "ViroDB::Result::DerivationProtocolOutput",
  {
    "foreign.derivation_protocol_id" => "self.derivation_protocol_id",
  },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2019-04-30 14:38:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:3gtYx5eR85EQw4RXWtCbPA

=head2 output_tissue_types
=cut

__PACKAGE__->many_to_many("output_tissue_types", "protocol_outputs", "tissue_type");

__PACKAGE__->meta->make_immutable;
1;
