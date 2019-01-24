use utf8;
package ViroDB::Result::LegacyProtocolType;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ViroDB::Result::LegacyProtocolType

=cut

use strict;
use warnings;

=head1 BASE CLASS: L<ViroDB::Result>

=cut

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'ViroDB::Result';

=head1 TABLE: C<viroserve.protocol_type>

=cut

__PACKAGE__->table("viroserve.protocol_type");

=head1 ACCESSORS

=head2 protocol_type_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'viroserve.protocol_type_protocol_type_id_seq'

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 45

=cut

__PACKAGE__->add_columns(
  "protocol_type_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "viroserve.protocol_type_protocol_type_id_seq",
  },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 45 },
);

=head1 PRIMARY KEY

=over 4

=item * L</protocol_type_id>

=back

=cut

__PACKAGE__->set_primary_key("protocol_type_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<protocol_type_name_key>

=over 4

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint("protocol_type_name_key", ["name"]);

=head1 RELATIONS

=head2 protocols

Type: has_many

Related object: L<ViroDB::Result::LegacyProtocol>

=cut

__PACKAGE__->has_many(
  "protocols",
  "ViroDB::Result::LegacyProtocol",
  { "foreign.protocol_type_id" => "self.protocol_type_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2017-08-11 15:11:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Wn0NwSV1ghluQ6ZToCWj4A


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
