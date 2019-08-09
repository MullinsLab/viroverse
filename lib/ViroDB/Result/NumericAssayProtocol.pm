use utf8;
package ViroDB::Result::NumericAssayProtocol;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ViroDB::Result::NumericAssayProtocol

=cut

use strict;
use warnings;

=head1 BASE CLASS: L<ViroDB::Result>

=cut

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'ViroDB::Result';

=head1 TABLE: C<viroserve.numeric_assay_protocol>

=cut

__PACKAGE__->table("viroserve.numeric_assay_protocol");

=head1 ACCESSORS

=head2 numeric_assay_protocol_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'viroserve.numeric_assay_protocol_numeric_assay_protocol_id_seq'

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 unit_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "numeric_assay_protocol_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "viroserve.numeric_assay_protocol_numeric_assay_protocol_id_seq",
  },
  "name",
  { data_type => "text", is_nullable => 0 },
  "unit_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</numeric_assay_protocol_id>

=back

=cut

__PACKAGE__->set_primary_key("numeric_assay_protocol_id");

=head1 RELATIONS

=head2 numeric_assay_results

Type: has_many

Related object: L<ViroDB::Result::NumericAssayResult>

=cut

__PACKAGE__->has_many(
  "numeric_assay_results",
  "ViroDB::Result::NumericAssayResult",
  {
    "foreign.numeric_assay_protocol_id" => "self.numeric_assay_protocol_id",
  },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 unit

Type: belongs_to

Related object: L<ViroDB::Result::Unit>

=cut

__PACKAGE__->belongs_to(
  "unit",
  "ViroDB::Result::Unit",
  { unit_id => "unit_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2019-08-01 14:52:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:V/7xcbwxG4Y72bNva+VpDg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
