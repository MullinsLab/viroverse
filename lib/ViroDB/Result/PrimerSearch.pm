use utf8;
package ViroDB::Result::PrimerSearch;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ViroDB::Result::PrimerSearch

=cut

use strict;
use warnings;

=head1 BASE CLASS: L<ViroDB::Result>

=cut

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'ViroDB::Result';

=head1 TABLE: C<viroserve.primer_search>

=cut

__PACKAGE__->table("viroserve.primer_search");

=head1 ACCESSORS

=head2 primer_id

  data_type: 'integer'
  is_nullable: 1

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 sequence

  accessor: 'sequence_bases'
  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 orientation

  data_type: 'char'
  is_nullable: 1
  size: 1

=head2 lab_common

  data_type: 'boolean'
  is_nullable: 1

=head2 notes

  data_type: 'text'
  is_nullable: 1

=head2 date_added

  data_type: 'date'
  is_nullable: 1

=head2 organism

  data_type: 'text'
  is_nullable: 1

=head2 positions

  data_type: 'numeric[]'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "primer_id",
  { data_type => "integer", is_nullable => 1 },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "sequence",
  {
    accessor => "sequence_bases",
    data_type => "varchar",
    is_nullable => 1,
    size => 255,
  },
  "orientation",
  { data_type => "char", is_nullable => 1, size => 1 },
  "lab_common",
  { data_type => "boolean", is_nullable => 1 },
  "notes",
  { data_type => "text", is_nullable => 1 },
  "date_added",
  { data_type => "date", is_nullable => 1 },
  "organism",
  { data_type => "text", is_nullable => 1 },
  "positions",
  { data_type => "numeric[]", is_nullable => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2019-07-24 17:18:42
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:9Sp3y4/5uBGKMCpjItlQdw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
