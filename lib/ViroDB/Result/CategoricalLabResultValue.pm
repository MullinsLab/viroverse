use utf8;
package ViroDB::Result::CategoricalLabResultValue;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ViroDB::Result::CategoricalLabResultValue

=cut

use strict;
use warnings;

=head1 BASE CLASS: L<ViroDB::Result>

=cut

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'ViroDB::Result';

=head1 TABLE: C<viroserve.lab_result_cat_value>

=cut

__PACKAGE__->table("viroserve.lab_result_cat_value");

=head1 ACCESSORS

=head2 lab_result_cat_value_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'viroserve.lab_result_cat_value_lab_result_cat_value_id_seq'

=head2 lab_result_cat_type_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 25

=cut

__PACKAGE__->add_columns(
  "lab_result_cat_value_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "viroserve.lab_result_cat_value_lab_result_cat_value_id_seq",
  },
  "lab_result_cat_type_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 25 },
);

=head1 PRIMARY KEY

=over 4

=item * L</lab_result_cat_value_id>

=back

=cut

__PACKAGE__->set_primary_key("lab_result_cat_value_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<lab_result_cat_value_unique_by_type>

=over 4

=item * L</lab_result_cat_type_id>

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "lab_result_cat_value_unique_by_type",
  ["lab_result_cat_type_id", "name"],
);

=head1 RELATIONS

=head2 lab_result_cat_type

Type: belongs_to

Related object: L<ViroDB::Result::CategoricalLabResultType>

=cut

__PACKAGE__->belongs_to(
  "lab_result_cat_type",
  "ViroDB::Result::CategoricalLabResultType",
  { lab_result_cat_type_id => "lab_result_cat_type_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 lab_result_cat_types

Type: has_many

Related object: L<ViroDB::Result::CategoricalLabResultType>

=cut

__PACKAGE__->has_many(
  "lab_result_cat_types",
  "ViroDB::Result::CategoricalLabResultType",
  {
    "foreign.normal_lab_result_cat_value_id" => "self.lab_result_cat_value_id",
  },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 results

Type: has_many

Related object: L<ViroDB::Result::CategoricalLabResult>

=cut

__PACKAGE__->has_many(
  "results",
  "ViroDB::Result::CategoricalLabResult",
  {
    "foreign.lab_result_cat_value_id" => "self.lab_result_cat_value_id",
  },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2017-08-11 15:11:37
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:cpoe/0jmygs+oBir5l4alQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
