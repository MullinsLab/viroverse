use utf8;
package ViroDB::Result::CopyNumberGelLane;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ViroDB::Result::CopyNumberGelLane

=cut

use strict;
use warnings;

=head1 BASE CLASS: L<ViroDB::Result>

=cut

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'ViroDB::Result';

=head1 TABLE: C<viroserve.copy_number_gel_lane>

=cut

__PACKAGE__->table("viroserve.copy_number_gel_lane");

=head1 ACCESSORS

=head2 copy_number_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 gel_lane_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "copy_number_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "gel_lane_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</copy_number_id>

=item * L</gel_lane_id>

=back

=cut

__PACKAGE__->set_primary_key("copy_number_id", "gel_lane_id");

=head1 RELATIONS

=head2 copy_number

Type: belongs_to

Related object: L<ViroDB::Result::CopyNumber>

=cut

__PACKAGE__->belongs_to(
  "copy_number",
  "ViroDB::Result::CopyNumber",
  { copy_number_id => "copy_number_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 gel_lane

Type: belongs_to

Related object: L<ViroDB::Result::GelLane>

=cut

__PACKAGE__->belongs_to(
  "gel_lane",
  "ViroDB::Result::GelLane",
  { gel_lane_id => "gel_lane_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2018-01-19 14:53:22
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:JvIzsnRWGQFs370P5giaOw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
