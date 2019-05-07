use utf8;
package ViroDB::Result::Enzyme;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ViroDB::Result::Enzyme

=cut

use strict;
use warnings;

=head1 BASE CLASS: L<ViroDB::Result>

=cut

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'ViroDB::Result';

=head1 TABLE: C<viroserve.enzyme>

=cut

__PACKAGE__->table("viroserve.enzyme");

=head1 ACCESSORS

=head2 enzyme_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'viroserve.enzyme_enzyme_id_seq'

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 short_name

  data_type: 'varchar'
  is_nullable: 1
  size: 30

=head2 type

  data_type: 'viroserve.enzyme_type'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "enzyme_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "viroserve.enzyme_enzyme_id_seq",
  },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "short_name",
  { data_type => "varchar", is_nullable => 1, size => 30 },
  "type",
  { data_type => "viroserve.enzyme_type", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</enzyme_id>

=back

=cut

__PACKAGE__->set_primary_key("enzyme_id");

=head1 RELATIONS

=head2 pcr_products

Type: has_many

Related object: L<ViroDB::Result::PolymeraseChainReactionProduct>

=cut

__PACKAGE__->has_many(
  "pcr_products",
  "ViroDB::Result::PolymeraseChainReactionProduct",
  { "foreign.enzyme_id" => "self.enzyme_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 rt_products

Type: has_many

Related object: L<ViroDB::Result::ReverseTranscriptionProduct>

=cut

__PACKAGE__->has_many(
  "rt_products",
  "ViroDB::Result::ReverseTranscriptionProduct",
  { "foreign.enzyme_id" => "self.enzyme_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2019-05-06 17:19:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:8JGrPTwygKIRMeRY5NAueg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
