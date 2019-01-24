use utf8;
package ViroDB::Result::NumericLabResultType;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ViroDB::Result::NumericLabResultType

=cut

use strict;
use warnings;

=head1 BASE CLASS: L<ViroDB::Result>

=cut

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'ViroDB::Result';

=head1 TABLE: C<viroserve.lab_result_num_type>

=cut

__PACKAGE__->table("viroserve.lab_result_num_type");

=head1 ACCESSORS

=head2 lab_result_num_type_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'viroserve.lab_result_num_type_lab_result_num_type_id_seq'

=head2 name

  data_type: 'text'
  is_nullable: 1

=head2 unit_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 normal_min

  data_type: 'integer'
  is_nullable: 1

=head2 normal_max

  data_type: 'integer'
  is_nullable: 1

=head2 note

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 vv_uid

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'viroserve.vv_uid'

=cut

__PACKAGE__->add_columns(
  "lab_result_num_type_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "viroserve.lab_result_num_type_lab_result_num_type_id_seq",
  },
  "name",
  { data_type => "text", is_nullable => 1 },
  "unit_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "normal_min",
  { data_type => "integer", is_nullable => 1 },
  "normal_max",
  { data_type => "integer", is_nullable => 1 },
  "note",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "vv_uid",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "viroserve.vv_uid",
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</lab_result_num_type_id>

=back

=cut

__PACKAGE__->set_primary_key("lab_result_num_type_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<lab_result_num_type_name_unique>

=over 4

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint("lab_result_num_type_name_unique", ["name"]);

=head1 RELATIONS

=head2 results

Type: has_many

Related object: L<ViroDB::Result::NumericLabResult>

=cut

__PACKAGE__->has_many(
  "results",
  "ViroDB::Result::NumericLabResult",
  {
    "foreign.lab_result_num_type_id" => "self.lab_result_num_type_id",
  },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 unit

Type: belongs_to

Related object: L<ViroDB::Result::Unit>

=cut

__PACKAGE__->belongs_to(
  "unit",
  "ViroDB::Result::Unit",
  { unit_id => "unit_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2017-08-11 15:11:37
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:+XGmiYUBxbYhYGY6+fWRfw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
