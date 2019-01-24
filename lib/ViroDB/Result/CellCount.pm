use utf8;
package ViroDB::Result::CellCount;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ViroDB::Result::CellCount

=cut

use strict;
use warnings;

=head1 BASE CLASS: L<ViroDB::Result>

=cut

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'ViroDB::Result';
__PACKAGE__->table_class("DBIx::Class::ResultSource::View");

=head1 TABLE: C<viroserve.cell_count>

=cut

__PACKAGE__->table("viroserve.cell_count");

=head1 ACCESSORS

=head2 patient_id

  data_type: 'integer'
  is_nullable: 1

=head2 visit_date

  data_type: 'date'
  is_nullable: 1

=head2 cell_type

  data_type: 'text'
  is_nullable: 1

=head2 value

  data_type: 'numeric'
  is_nullable: 1

=head2 date_added

  data_type: 'date'
  is_nullable: 1

=head2 lab_result_num_id

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "patient_id",
  { data_type => "integer", is_nullable => 1 },
  "visit_date",
  { data_type => "date", is_nullable => 1 },
  "cell_type",
  { data_type => "text", is_nullable => 1 },
  "value",
  { data_type => "numeric", is_nullable => 1 },
  "date_added",
  { data_type => "date", is_nullable => 1 },
  "lab_result_num_id",
  { data_type => "integer", is_nullable => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2017-08-11 15:11:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:uIOyDjwr0e7Uyo0sLfNwIA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
