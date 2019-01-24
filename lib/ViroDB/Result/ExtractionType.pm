use utf8;
package ViroDB::Result::ExtractionType;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ViroDB::Result::ExtractionType

=cut

use strict;
use warnings;

=head1 BASE CLASS: L<ViroDB::Result>

=cut

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'ViroDB::Result';

=head1 TABLE: C<viroserve.extract_type>

=cut

__PACKAGE__->table("viroserve.extract_type");

=head1 ACCESSORS

=head2 extract_type_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'viroserve.extract_type_extract_type_id_seq'

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 15

=cut

__PACKAGE__->add_columns(
  "extract_type_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "viroserve.extract_type_extract_type_id_seq",
  },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 15 },
);

=head1 PRIMARY KEY

=over 4

=item * L</extract_type_id>

=back

=cut

__PACKAGE__->set_primary_key("extract_type_id");

=head1 RELATIONS

=head2 extractions

Type: has_many

Related object: L<ViroDB::Result::Extraction>

=cut

__PACKAGE__->has_many(
  "extractions",
  "ViroDB::Result::Extraction",
  { "foreign.extract_type_id" => "self.extract_type_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2017-09-07 13:34:53
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:yQwNC3qL4saN3aWpNk9v5A


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
