use utf8;
package ViroDB::Result::Additive;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ViroDB::Result::Additive

=cut

use strict;
use warnings;

=head1 BASE CLASS: L<ViroDB::Result>

=cut

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'ViroDB::Result';

=head1 TABLE: C<viroserve.additive>

=cut

__PACKAGE__->table("viroserve.additive");

=head1 ACCESSORS

=head2 additive_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'viroserve.additive_additive_id_seq'

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 45

=head2 created

  data_type: 'date'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=cut

__PACKAGE__->add_columns(
  "additive_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "viroserve.additive_additive_id_seq",
  },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 45 },
  "created",
  {
    data_type     => "date",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</additive_id>

=back

=cut

__PACKAGE__->set_primary_key("additive_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<additive_name_unique>

=over 4

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint("additive_name_unique", ["name"]);

=head1 RELATIONS

=head2 samples

Type: has_many

Related object: L<ViroDB::Result::Sample>

=cut

__PACKAGE__->has_many(
  "samples",
  "ViroDB::Result::Sample",
  { "foreign.additive_id" => "self.additive_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2017-08-11 15:11:37
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:D6FPPLmc6GEH4hcICF6pTQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
