use utf8;
package ViroDB::Result::Primer;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ViroDB::Result::Primer

=cut

use strict;
use warnings;

=head1 BASE CLASS: L<ViroDB::Result>

=cut

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'ViroDB::Result';

=head1 TABLE: C<viroserve.primer>

=cut

__PACKAGE__->table("viroserve.primer");

=head1 ACCESSORS

=head2 primer_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'viroserve.primer_primer_id_seq'

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 45

=head2 sequence

  accessor: 'sequence_bases'
  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 orientation

  data_type: 'char'
  is_nullable: 1
  size: 1

=head2 lab_common

  data_type: 'boolean'
  default_value: false
  is_nullable: 1

=head2 notes

  data_type: 'text'
  is_nullable: 1

=head2 vv_uid

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'viroserve.vv_uid'

=head2 date_added

  data_type: 'date'
  default_value: current_timestamp
  is_nullable: 1
  original: {default_value => \"now()"}

=head2 organism_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "primer_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "viroserve.primer_primer_id_seq",
  },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 45 },
  "sequence",
  {
    accessor => "sequence_bases",
    data_type => "varchar",
    is_nullable => 0,
    size => 255,
  },
  "orientation",
  { data_type => "char", is_nullable => 1, size => 1 },
  "lab_common",
  { data_type => "boolean", default_value => \"false", is_nullable => 1 },
  "notes",
  { data_type => "text", is_nullable => 1 },
  "vv_uid",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "viroserve.vv_uid",
  },
  "date_added",
  {
    data_type     => "date",
    default_value => \"current_timestamp",
    is_nullable   => 1,
    original      => { default_value => \"now()" },
  },
  "organism_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</primer_id>

=back

=cut

__PACKAGE__->set_primary_key("primer_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<primer_unique_name_sequence>

=over 4

=item * L</name>

=item * L</sequence>

=back

=cut

__PACKAGE__->add_unique_constraint("primer_unique_name_sequence", ["name", "sequence"]);

=head1 RELATIONS

=head2 chromats

Type: has_many

Related object: L<ViroDB::Result::Chromat>

=cut

__PACKAGE__->has_many(
  "chromats",
  "ViroDB::Result::Chromat",
  { "foreign.primer_id" => "self.primer_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 organism

Type: belongs_to

Related object: L<ViroDB::Result::Organism>

=cut

__PACKAGE__->belongs_to(
  "organism",
  "ViroDB::Result::Organism",
  { organism_id => "organism_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 pcr_product_assignments

Type: has_many

Related object: L<ViroDB::Result::PolymeraseChainReactionProductPrimer>

=cut

__PACKAGE__->has_many(
  "pcr_product_assignments",
  "ViroDB::Result::PolymeraseChainReactionProductPrimer",
  { "foreign.primer_id" => "self.primer_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 positions

Type: has_many

Related object: L<ViroDB::Result::PrimerPosition>

=cut

__PACKAGE__->has_many(
  "positions",
  "ViroDB::Result::PrimerPosition",
  { "foreign.primer_id" => "self.primer_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 pcr_products

Type: many_to_many

Composing rels: L</pcr_product_assignments> -> pcr_product

=cut

__PACKAGE__->many_to_many("pcr_products", "pcr_product_assignments", "pcr_product");


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2019-07-24 15:52:57
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:l3/FN2I41IGp1X8p/GMBQQ

sub as_hash {
    my $self = shift;
    my $hash = $self->next::method;
    $hash->{organism} = $self->organism->name
        if $self->organism;
    $hash->{positions} = [
        map { $self->orientation eq "F" ? $_->hxb2_end : $_->hxb2_start } $self->positions
    ] if $self->positions;
    return $hash;
}

__PACKAGE__->meta->make_immutable;
1;
