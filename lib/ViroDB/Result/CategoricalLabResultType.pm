use utf8;
package ViroDB::Result::CategoricalLabResultType;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ViroDB::Result::CategoricalLabResultType

=cut

use strict;
use warnings;

=head1 BASE CLASS: L<ViroDB::Result>

=cut

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'ViroDB::Result';

=head1 TABLE: C<viroserve.lab_result_cat_type>

=cut

__PACKAGE__->table("viroserve.lab_result_cat_type");

=head1 ACCESSORS

=head2 lab_result_cat_type_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'viroserve.lab_result_cat_type_lab_result_cat_type_id_seq'

=head2 name

  data_type: 'text'
  is_nullable: 1

=head2 note

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 normal_lab_result_cat_value_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 vv_uid

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 1
  sequence: 'viroserve.vv_uid'

=cut

__PACKAGE__->add_columns(
  "lab_result_cat_type_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "viroserve.lab_result_cat_type_lab_result_cat_type_id_seq",
  },
  "name",
  { data_type => "text", is_nullable => 1 },
  "note",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "normal_lab_result_cat_value_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "vv_uid",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 1,
    sequence          => "viroserve.vv_uid",
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</lab_result_cat_type_id>

=back

=cut

__PACKAGE__->set_primary_key("lab_result_cat_type_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<lab_result_cat_type_name_unique>

=over 4

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint("lab_result_cat_type_name_unique", ["name"]);

=head1 RELATIONS

=head2 lab_result_cat_values

Type: has_many

Related object: L<ViroDB::Result::CategoricalLabResultValue>

=cut

__PACKAGE__->has_many(
  "lab_result_cat_values",
  "ViroDB::Result::CategoricalLabResultValue",
  {
    "foreign.lab_result_cat_type_id" => "self.lab_result_cat_type_id",
  },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 normal_lab_result_cat_value

Type: belongs_to

Related object: L<ViroDB::Result::CategoricalLabResultValue>

=cut

__PACKAGE__->belongs_to(
  "normal_lab_result_cat_value",
  "ViroDB::Result::CategoricalLabResultValue",
  { lab_result_cat_value_id => "normal_lab_result_cat_value_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 results

Type: has_many

Related object: L<ViroDB::Result::CategoricalLabResult>

=cut

__PACKAGE__->has_many(
  "results",
  "ViroDB::Result::CategoricalLabResult",
  {
    "foreign.lab_result_cat_type_id" => "self.lab_result_cat_type_id",
  },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2017-08-11 15:11:37
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:WqnBHWv1gaFdbNdZlVMCMA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
