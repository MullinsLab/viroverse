use utf8;
package ViroDB::Result::TissueType;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ViroDB::Result::TissueType

=cut

use strict;
use warnings;

=head1 BASE CLASS: L<ViroDB::Result>

=cut

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'ViroDB::Result';

=head1 TABLE: C<viroserve.tissue_type>

=cut

__PACKAGE__->table("viroserve.tissue_type");

=head1 ACCESSORS

=head2 tissue_type_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'viroserve.tissue_type_tissue_type_id_seq'

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 45

=cut

__PACKAGE__->add_columns(
  "tissue_type_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "viroserve.tissue_type_tissue_type_id_seq",
  },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 45 },
);

=head1 PRIMARY KEY

=over 4

=item * L</tissue_type_id>

=back

=cut

__PACKAGE__->set_primary_key("tissue_type_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<tissue_type_name_key>

=over 4

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint("tissue_type_name_key", ["name"]);

=head1 RELATIONS

=head2 protocol_outputs

Type: has_many

Related object: L<ViroDB::Result::DerivationProtocolOutput>

=cut

__PACKAGE__->has_many(
  "protocol_outputs",
  "ViroDB::Result::DerivationProtocolOutput",
  { "foreign.tissue_type_id" => "self.tissue_type_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 samples

Type: has_many

Related object: L<ViroDB::Result::Sample>

=cut

__PACKAGE__->has_many(
  "samples",
  "ViroDB::Result::Sample",
  { "foreign.tissue_type_id" => "self.tissue_type_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2019-04-30 14:38:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:zwap0rQ0UuhZg6xj3T2/aw

__PACKAGE__->many_to_many("protocols", "protocol_outputs", "protocol");

__PACKAGE__->meta->make_immutable;
1;
