use utf8;
package ViroDB::Result::PolymeraseChainReactionProductPrimer;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ViroDB::Result::PolymeraseChainReactionProductPrimer

=cut

use strict;
use warnings;

=head1 BASE CLASS: L<ViroDB::Result>

=cut

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'ViroDB::Result';

=head1 TABLE: C<viroserve.pcr_product_primer>

=cut

__PACKAGE__->table("viroserve.pcr_product_primer");

=head1 ACCESSORS

=head2 pcr_product_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 primer_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "pcr_product_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "primer_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</pcr_product_id>

=item * L</primer_id>

=back

=cut

__PACKAGE__->set_primary_key("pcr_product_id", "primer_id");

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

=head2 primer

Type: belongs_to

Related object: L<ViroDB::Result::Primer>

=cut

__PACKAGE__->belongs_to(
  "primer",
  "ViroDB::Result::Primer",
  { primer_id => "primer_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2017-12-14 14:44:45
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:tGVF0oEz/5oXV0tvcwvubg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
