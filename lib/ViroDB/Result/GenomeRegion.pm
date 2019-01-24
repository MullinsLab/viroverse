use utf8;
package ViroDB::Result::GenomeRegion;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ViroDB::Result::GenomeRegion

=cut

use strict;
use warnings;

=head1 BASE CLASS: L<ViroDB::Result>

=cut

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'ViroDB::Result';

=head1 TABLE: C<viroserve.genome_region>

=cut

__PACKAGE__->table("viroserve.genome_region");

=head1 ACCESSORS

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 base_start

  data_type: 'integer'
  is_nullable: 0

=head2 base_end

  data_type: 'integer'
  is_nullable: 0

=head2 base_range

  data_type: 'int4range'
  is_nullable: 0

=head2 reading_frame

  data_type: 'numeric'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "name",
  { data_type => "text", is_nullable => 0 },
  "base_start",
  { data_type => "integer", is_nullable => 0 },
  "base_end",
  { data_type => "integer", is_nullable => 0 },
  "base_range",
  { data_type => "int4range", is_nullable => 0 },
  "reading_frame",
  { data_type => "numeric", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</name>

=back

=cut

__PACKAGE__->set_primary_key("name");


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2017-08-11 15:11:37
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:vIt32LfsNqYi8SOvweSJNg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
