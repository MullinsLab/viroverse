use utf8;
package ViroDB::Result::Gel;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ViroDB::Result::Gel

=cut

use strict;
use warnings;

=head1 BASE CLASS: L<ViroDB::Result>

=cut

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'ViroDB::Result';

=head1 TABLE: C<viroserve.gel>

=cut

__PACKAGE__->table("viroserve.gel");

=head1 ACCESSORS

=head2 gel_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'viroserve.gel_gel_id_seq'

=head2 protocol_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 scientist_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 date_completed

  data_type: 'date'
  is_nullable: 1

=head2 date_entered

  data_type: 'date'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=head2 notes

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 image

  data_type: 'bytea'
  is_nullable: 1

=head2 vv_uid

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'viroserve.vv_uid'

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 mime_type

  data_type: 'varchar'
  is_nullable: 0
  size: 40

=head2 ninety_six_well

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "gel_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "viroserve.gel_gel_id_seq",
  },
  "protocol_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "scientist_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "date_completed",
  { data_type => "date", is_nullable => 1 },
  "date_entered",
  {
    data_type     => "date",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "notes",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "image",
  { data_type => "bytea", is_nullable => 1 },
  "vv_uid",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "viroserve.vv_uid",
  },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "mime_type",
  { data_type => "varchar", is_nullable => 0, size => 40 },
  "ninety_six_well",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</gel_id>

=back

=cut

__PACKAGE__->set_primary_key("gel_id");

=head1 RELATIONS

=head2 gel_lanes

Type: has_many

Related object: L<ViroDB::Result::GelLane>

=cut

__PACKAGE__->has_many(
  "gel_lanes",
  "ViroDB::Result::GelLane",
  { "foreign.gel_id" => "self.gel_id" },
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


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2018-01-26 10:45:22
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:+sBJM+otObIT09cEX0Qr6w


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
