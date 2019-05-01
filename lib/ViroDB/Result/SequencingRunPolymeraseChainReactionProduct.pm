use utf8;
package ViroDB::Result::SequencingRunPolymeraseChainReactionProduct;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ViroDB::Result::SequencingRunPolymeraseChainReactionProduct

=cut

use strict;
use warnings;

=head1 BASE CLASS: L<ViroDB::Result>

=cut

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'ViroDB::Result';

=head1 TABLE: C<viroserve.sequencing_run_pcr_product>

=cut

__PACKAGE__->table("viroserve.sequencing_run_pcr_product");

=head1 ACCESSORS

=head2 sequencing_run_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 pcr_product_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "sequencing_run_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "pcr_product_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 UNIQUE CONSTRAINTS

=head2 C<sequencing_run_pcr_product_sequencing_run_id_pcr_product_id_key>

=over 4

=item * L</sequencing_run_id>

=item * L</pcr_product_id>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "sequencing_run_pcr_product_sequencing_run_id_pcr_product_id_key",
  ["sequencing_run_id", "pcr_product_id"],
);

=head1 RELATIONS

=head2 pcr_product

Type: belongs_to

Related object: L<ViroDB::Result::PolymeraseChainReactionProduct>

=cut

__PACKAGE__->belongs_to(
  "pcr_product",
  "ViroDB::Result::PolymeraseChainReactionProduct",
  { pcr_product_id => "pcr_product_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 sequencing_run

Type: belongs_to

Related object: L<ViroDB::Result::SequencingRun>

=cut

__PACKAGE__->belongs_to(
  "sequencing_run",
  "ViroDB::Result::SequencingRun",
  { sequencing_run_id => "sequencing_run_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2019-04-30 17:01:04
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:BA8mx2srgitwVyicFBywvg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
