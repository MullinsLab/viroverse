use utf8;
package ViroDB::Result::GelLane;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ViroDB::Result::GelLane

=cut

use strict;
use warnings;

=head1 BASE CLASS: L<ViroDB::Result>

=cut

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'ViroDB::Result';

=head1 TABLE: C<viroserve.gel_lane>

=cut

__PACKAGE__->table("viroserve.gel_lane");

=head1 ACCESSORS

=head2 gel_lane_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'viroserve.gel_lane_gel_lane_id_seq'

=head2 gel_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 pcr_product_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 loc_x

  data_type: 'integer'
  is_nullable: 1

=head2 loc_y

  data_type: 'integer'
  is_nullable: 1

=head2 label

  data_type: 'varchar'
  is_nullable: 1
  size: 5

=head2 pos_result

  data_type: 'boolean'
  is_nullable: 1

=head2 vv_uid

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'viroserve.vv_uid'

=cut

__PACKAGE__->add_columns(
  "gel_lane_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "viroserve.gel_lane_gel_lane_id_seq",
  },
  "gel_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "pcr_product_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "loc_x",
  { data_type => "integer", is_nullable => 1 },
  "loc_y",
  { data_type => "integer", is_nullable => 1 },
  "label",
  { data_type => "varchar", is_nullable => 1, size => 5 },
  "pos_result",
  { data_type => "boolean", is_nullable => 1 },
  "vv_uid",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "viroserve.vv_uid",
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</gel_lane_id>

=back

=cut

__PACKAGE__->set_primary_key("gel_lane_id");

=head1 RELATIONS

=head2 copy_number_gel_lanes

Type: has_many

Related object: L<ViroDB::Result::CopyNumberGelLane>

=cut

__PACKAGE__->has_many(
  "copy_number_gel_lanes",
  "ViroDB::Result::CopyNumberGelLane",
  { "foreign.gel_lane_id" => "self.gel_lane_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 gel

Type: belongs_to

Related object: L<ViroDB::Result::Gel>

=cut

__PACKAGE__->belongs_to(
  "gel",
  "ViroDB::Result::Gel",
  { gel_id => "gel_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 pcr_product

Type: belongs_to

Related object: L<ViroDB::Result::PolymeraseChainReactionProduct>

=cut

__PACKAGE__->belongs_to(
  "pcr_product",
  "ViroDB::Result::PolymeraseChainReactionProduct",
  { pcr_product_id => "pcr_product_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 copy_numbers

Type: many_to_many

Composing rels: L</copy_number_gel_lanes> -> copy_number

=cut

__PACKAGE__->many_to_many("copy_numbers", "copy_number_gel_lanes", "copy_number");


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2018-12-28 14:59:46
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:2Mvnknk4Q5Gbaw1Hkhwr7g


sub formatted_label {
    my $self = shift;

    return $self->label
        unless $self->gel->ninety_six_well;

    die "Ninety-six well gel labels must be 1-96"
        unless $self->label >= 0 and $self->label <= 96;

    # Label is an integer from 1-96, numbering by row (A-H) then column (1-12).
    my $int     = $self->label - 1;
    my $alpha   = ('A'..'H')[ int($int / 12) ];
    my $numeric = $int % 12 + 1;

    return sprintf "%s%02d", $alpha, $numeric;
}

__PACKAGE__->meta->make_immutable;
1;
