use utf8;
package ViroDB::Result::PacbioPool;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ViroDB::Result::PacbioPool

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

=head1 TABLE: C<viroserve.pacbio_pool>

=cut

__PACKAGE__->table("viroserve.pacbio_pool");

=head1 ACCESSORS

=head2 sample_id

  data_type: 'integer'
  is_nullable: 1

=head2 sample_name

  data_type: 'varchar'
  is_nullable: 1
  size: 25

=head2 pcr_product_id

  data_type: 'integer'
  is_nullable: 1

=head2 pcr_nickname

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 rt_primer

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 scientist

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 date_completed

  data_type: 'date'
  is_nullable: 1

=head2 r2_pcr_primers

  data_type: 'character varying[]'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "sample_id",
  { data_type => "integer", is_nullable => 1 },
  "sample_name",
  { data_type => "varchar", is_nullable => 1, size => 25 },
  "pcr_product_id",
  { data_type => "integer", is_nullable => 1 },
  "pcr_nickname",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "rt_primer",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "scientist",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "date_completed",
  { data_type => "date", is_nullable => 1 },
  "r2_pcr_primers",
  { data_type => "character varying[]", is_nullable => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2019-08-15 10:51:50
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:8+lQS0tEIZPn2wayh/+jqw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
