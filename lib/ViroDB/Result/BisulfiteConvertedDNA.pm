use utf8;
package ViroDB::Result::BisulfiteConvertedDNA;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ViroDB::Result::BisulfiteConvertedDNA

=cut

use strict;
use warnings;

=head1 BASE CLASS: L<ViroDB::Result>

=cut

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'ViroDB::Result';

=head1 TABLE: C<viroserve.bisulfite_converted_dna>

=cut

__PACKAGE__->table("viroserve.bisulfite_converted_dna");

=head1 ACCESSORS

=head2 bisulfite_converted_dna_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'viroserve.bisulfite_converted_dna_bisulfite_converted_dna_id_seq'

=head2 extraction_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 rt_product_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 sample_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 protocol_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 scientist_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 date_entered

  data_type: 'date'
  default_value: current_timestamp
  is_nullable: 1
  original: {default_value => \"now()"}

=head2 date_completed

  data_type: 'date'
  is_nullable: 1

=head2 note

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "bisulfite_converted_dna_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "viroserve.bisulfite_converted_dna_bisulfite_converted_dna_id_seq",
  },
  "extraction_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "rt_product_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "sample_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "protocol_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "scientist_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "date_entered",
  {
    data_type     => "date",
    default_value => \"current_timestamp",
    is_nullable   => 1,
    original      => { default_value => \"now()" },
  },
  "date_completed",
  { data_type => "date", is_nullable => 1 },
  "note",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</bisulfite_converted_dna_id>

=back

=cut

__PACKAGE__->set_primary_key("bisulfite_converted_dna_id");

=head1 RELATIONS

=head2 copy_numbers

Type: has_many

Related object: L<ViroDB::Result::CopyNumber>

=cut

__PACKAGE__->has_many(
  "copy_numbers",
  "ViroDB::Result::CopyNumber",
  {
    "foreign.bisulfite_converted_dna_id" => "self.bisulfite_converted_dna_id",
  },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 extraction

Type: belongs_to

Related object: L<ViroDB::Result::Extraction>

=cut

__PACKAGE__->belongs_to(
  "extraction",
  "ViroDB::Result::Extraction",
  { extraction_id => "extraction_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 pcr_templates

Type: has_many

Related object: L<ViroDB::Result::PolymeraseChainReactionTemplate>

=cut

__PACKAGE__->has_many(
  "pcr_templates",
  "ViroDB::Result::PolymeraseChainReactionTemplate",
  {
    "foreign.bisulfite_converted_dna_id" => "self.bisulfite_converted_dna_id",
  },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 protocol

Type: belongs_to

Related object: L<ViroDB::Result::LegacyProtocol>

=cut

__PACKAGE__->belongs_to(
  "protocol",
  "ViroDB::Result::LegacyProtocol",
  { protocol_id => "protocol_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 rt_product

Type: belongs_to

Related object: L<ViroDB::Result::ReverseTranscriptionProduct>

=cut

__PACKAGE__->belongs_to(
  "rt_product",
  "ViroDB::Result::ReverseTranscriptionProduct",
  { rt_product_id => "rt_product_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

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
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2019-04-08 14:52:37
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:nCB6wtj7ABadyo4HbESrAA

sub input_product {
    my $self = shift;
    return $self->sample || $self->extraction || $self->rt_product;
}
with 'Viroverse::Model::Role::MolecularProduct';

__PACKAGE__->meta->make_immutable;
1;
