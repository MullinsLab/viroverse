use utf8;
package ViroDB::Result::CopyNumber;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ViroDB::Result::CopyNumber

=cut

use strict;
use warnings;

=head1 BASE CLASS: L<ViroDB::Result>

=cut

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'ViroDB::Result';

=head1 TABLE: C<viroserve.copy_number>

=cut

__PACKAGE__->table("viroserve.copy_number");

=head1 ACCESSORS

=head2 copy_number_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'viroserve.copy_number_copy_number_id_seq'

=head2 rt_product_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 extraction_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 value

  data_type: 'numeric'
  is_nullable: 1

=head2 std_error

  data_type: 'numeric'
  is_nullable: 1

=head2 vv_uid

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'viroserve.vv_uid'

=head2 scientist_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 date_created

  data_type: 'date'
  default_value: current_timestamp
  is_nullable: 1
  original: {default_value => \"now()"}

=head2 key

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 rec_addition

  data_type: 'numeric'
  is_nullable: 1

=head2 dil_table

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 sample_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 bisulfite_converted_dna_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "copy_number_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "viroserve.copy_number_copy_number_id_seq",
  },
  "rt_product_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "extraction_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "value",
  { data_type => "numeric", is_nullable => 1 },
  "std_error",
  { data_type => "numeric", is_nullable => 1 },
  "vv_uid",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "viroserve.vv_uid",
  },
  "scientist_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "date_created",
  {
    data_type     => "date",
    default_value => \"current_timestamp",
    is_nullable   => 1,
    original      => { default_value => \"now()" },
  },
  "key",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "rec_addition",
  { data_type => "numeric", is_nullable => 1 },
  "dil_table",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "sample_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "bisulfite_converted_dna_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</copy_number_id>

=back

=cut

__PACKAGE__->set_primary_key("copy_number_id");

=head1 RELATIONS

=head2 bisulfite_converted_dna

Type: belongs_to

Related object: L<ViroDB::Result::BisulfiteConvertedDNA>

=cut

__PACKAGE__->belongs_to(
  "bisulfite_converted_dna",
  "ViroDB::Result::BisulfiteConvertedDNA",
  { bisulfite_converted_dna_id => "bisulfite_converted_dna_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 copy_number_gel_lanes

Type: has_many

Related object: L<ViroDB::Result::CopyNumberGelLane>

=cut

__PACKAGE__->has_many(
  "copy_number_gel_lanes",
  "ViroDB::Result::CopyNumberGelLane",
  { "foreign.copy_number_id" => "self.copy_number_id" },
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

=head2 gel_lanes

Type: many_to_many

Composing rels: L</copy_number_gel_lanes> -> gel_lane

=cut

__PACKAGE__->many_to_many("gel_lanes", "copy_number_gel_lanes", "gel_lane");


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2019-04-08 14:52:37
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:2raLeW+VX9Ke8ianAX6nMg


sub pcr_primers {
    my $self = shift;

    # NOTE: using `first` below to arbitrarily select an associated gel lane
    # to get primers from is kind of fishy, though it should be true that
    # all associated PCR products have the same primers.
    return map { $_->name } $self->gel_lanes->first->pcr_product->primers->all;
}

sub input_sample {
    my $self  = shift;
    return $self->sample ||
        ($self->extraction and $self->extraction->sample) ||
        ($self->rt_product->extraction->sample);
}

__PACKAGE__->meta->make_immutable;
1;
