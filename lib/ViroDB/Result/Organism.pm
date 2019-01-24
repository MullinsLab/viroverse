use utf8;
package ViroDB::Result::Organism;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ViroDB::Result::Organism

=cut

use strict;
use warnings;

=head1 BASE CLASS: L<ViroDB::Result>

=cut

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'ViroDB::Result';

=head1 TABLE: C<viroserve.organism>

=cut

__PACKAGE__->table("viroserve.organism");

=head1 ACCESSORS

=head2 organism_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'viroserve.organism_organism_id_seq'

=head2 name

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "organism_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "viroserve.organism_organism_id_seq",
  },
  "name",
  { data_type => "text", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</organism_id>

=back

=cut

__PACKAGE__->set_primary_key("organism_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<organism_name_key>

=over 4

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint("organism_name_key", ["name"]);

=head1 RELATIONS

=head2 primers

Type: has_many

Related object: L<ViroDB::Result::Primer>

=cut

__PACKAGE__->has_many(
  "primers",
  "ViroDB::Result::Primer",
  { "foreign.organism_id" => "self.organism_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2017-08-11 17:07:02
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Tg+47I/HFvy7qKlOrxaQyA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
