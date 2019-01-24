use utf8;
package ViroDB::Result::ChromatType;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ViroDB::Result::ChromatType

=cut

use strict;
use warnings;

=head1 BASE CLASS: L<ViroDB::Result>

=cut

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'ViroDB::Result';

=head1 TABLE: C<viroserve.chromat_type>

=cut

__PACKAGE__->table("viroserve.chromat_type");

=head1 ACCESSORS

=head2 chromat_type_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'viroserve.chromat_type_chromat_type_id_seq'

=head2 ident_string

  data_type: 'varchar'
  is_nullable: 0
  size: 25

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 date_added

  data_type: 'date'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=cut

__PACKAGE__->add_columns(
  "chromat_type_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "viroserve.chromat_type_chromat_type_id_seq",
  },
  "ident_string",
  { data_type => "varchar", is_nullable => 0, size => 25 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "date_added",
  {
    data_type     => "date",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</chromat_type_id>

=back

=cut

__PACKAGE__->set_primary_key("chromat_type_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<chromat_type_ident_string_key>

=over 4

=item * L</ident_string>

=back

=cut

__PACKAGE__->add_unique_constraint("chromat_type_ident_string_key", ["ident_string"]);

=head1 RELATIONS

=head2 chromats

Type: has_many

Related object: L<ViroDB::Result::Chromat>

=cut

__PACKAGE__->has_many(
  "chromats",
  "ViroDB::Result::Chromat",
  { "foreign.chromat_type_id" => "self.chromat_type_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2017-11-01 09:30:11
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:a05yUUwH4LqQEXRuCFB8AA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
