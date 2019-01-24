use utf8;
package ViroDB::Result::NumericLabResult;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ViroDB::Result::NumericLabResult

=cut

use strict;
use warnings;

=head1 BASE CLASS: L<ViroDB::Result>

=cut

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'ViroDB::Result';

=head1 TABLE: C<viroserve.lab_result_num>

=cut

__PACKAGE__->table("viroserve.lab_result_num");

=head1 ACCESSORS

=head2 lab_result_num_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'viroserve.lab_result_num_lab_result_num_id_seq'

=head2 lab_result_num_type_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 sample_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 scientist_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 date_performed

  data_type: 'date'
  is_nullable: 1

=head2 value

  data_type: 'numeric'
  is_nullable: 0

=head2 note

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 vv_uid

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 1
  sequence: 'viroserve.vv_uid'

=head2 date_added

  data_type: 'date'
  default_value: current_timestamp
  is_nullable: 1
  original: {default_value => \"now()"}

=head2 visit_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "lab_result_num_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "viroserve.lab_result_num_lab_result_num_id_seq",
  },
  "lab_result_num_type_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "sample_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "scientist_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "date_performed",
  { data_type => "date", is_nullable => 1 },
  "value",
  { data_type => "numeric", is_nullable => 0 },
  "note",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "vv_uid",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 1,
    sequence          => "viroserve.vv_uid",
  },
  "date_added",
  {
    data_type     => "date",
    default_value => \"current_timestamp",
    is_nullable   => 1,
    original      => { default_value => \"now()" },
  },
  "visit_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</lab_result_num_id>

=back

=cut

__PACKAGE__->set_primary_key("lab_result_num_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<lab_result_num_visit_type_idx>

=over 4

=item * L</visit_id>

=item * L</lab_result_num_type_id>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "lab_result_num_visit_type_idx",
  ["visit_id", "lab_result_num_type_id"],
);

=head1 RELATIONS

=head2 sample

Type: belongs_to

Related object: L<ViroDB::Result::Sample>

=cut

__PACKAGE__->belongs_to(
  "sample",
  "ViroDB::Result::Sample",
  { sample_id => "sample_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 scientist

Type: belongs_to

Related object: L<ViroDB::Result::Scientist>

=cut

__PACKAGE__->belongs_to(
  "scientist",
  "ViroDB::Result::Scientist",
  { scientist_id => "scientist_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 type

Type: belongs_to

Related object: L<ViroDB::Result::NumericLabResultType>

=cut

__PACKAGE__->belongs_to(
  "type",
  "ViroDB::Result::NumericLabResultType",
  { lab_result_num_type_id => "lab_result_num_type_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 visit

Type: belongs_to

Related object: L<ViroDB::Result::Visit>

=cut

__PACKAGE__->belongs_to(
  "visit",
  "ViroDB::Result::Visit",
  { visit_id => "visit_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2017-08-11 15:11:37
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:i45yUH7MlSZ+Q0808ddjSg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
