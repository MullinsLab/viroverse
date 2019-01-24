use utf8;
package ViroDB::Result::SequenceChromat;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ViroDB::Result::SequenceChromat

=cut

use strict;
use warnings;

=head1 BASE CLASS: L<ViroDB::Result>

=cut

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'ViroDB::Result';

=head1 TABLE: C<viroserve.chromat_na_sequence>

=cut

__PACKAGE__->table("viroserve.chromat_na_sequence");

=head1 ACCESSORS

=head2 chromat_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 na_sequence_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 na_sequence_revision

  data_type: 'smallint'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "chromat_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "na_sequence_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "na_sequence_revision",
  { data_type => "smallint", is_foreign_key => 1, is_nullable => 1 },
);

=head1 UNIQUE CONSTRAINTS

=head2 C<chromat_na_sequence_unique_join_keys>

=over 4

=item * L</chromat_id>

=item * L</na_sequence_id>

=item * L</na_sequence_revision>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "chromat_na_sequence_unique_join_keys",
  ["chromat_id", "na_sequence_id", "na_sequence_revision"],
);

=head1 RELATIONS

=head2 chromat

Type: belongs_to

Related object: L<ViroDB::Result::Chromat>

=cut

__PACKAGE__->belongs_to(
  "chromat",
  "ViroDB::Result::Chromat",
  { chromat_id => "chromat_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 na_sequence

Type: belongs_to

Related object: L<ViroDB::Result::NucleicAcidSequence>

=cut

__PACKAGE__->belongs_to(
  "na_sequence",
  "ViroDB::Result::NucleicAcidSequence",
  {
    na_sequence_id       => "na_sequence_id",
    na_sequence_revision => "na_sequence_revision",
  },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2017-08-11 15:11:37
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:9Yu9HwIyiEwAe+O9/itXQg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
