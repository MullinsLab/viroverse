use utf8;
package ViroDB::Result::PrimerPosition;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ViroDB::Result::PrimerPosition

=cut

use strict;
use warnings;

=head1 BASE CLASS: L<ViroDB::Result>

=cut

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'ViroDB::Result';

=head1 TABLE: C<viroserve.primer_position>

=cut

__PACKAGE__->table("viroserve.primer_position");

=head1 ACCESSORS

=head2 primer_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 hxb2_start

  data_type: 'integer'
  is_nullable: 0

=head2 hxb2_end

  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "primer_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "hxb2_start",
  { data_type => "integer", is_nullable => 0 },
  "hxb2_end",
  { data_type => "integer", is_nullable => 0 },
);

=head1 UNIQUE CONSTRAINTS

=head2 C<primer_position_primer_id_hxb2_start_hxb2_end_key>

=over 4

=item * L</primer_id>

=item * L</hxb2_start>

=item * L</hxb2_end>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "primer_position_primer_id_hxb2_start_hxb2_end_key",
  ["primer_id", "hxb2_start", "hxb2_end"],
);

=head1 RELATIONS

=head2 primer

Type: belongs_to

Related object: L<ViroDB::Result::Primer>

=cut

__PACKAGE__->belongs_to(
  "primer",
  "ViroDB::Result::Primer",
  { primer_id => "primer_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2018-12-28 10:44:31
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:HQ43EV/CGYDxwcpr1JjcpQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
