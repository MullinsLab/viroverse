use utf8;
package ViroDB::Result::Extraction;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ViroDB::Result::Extraction

=cut

use strict;
use warnings;

=head1 BASE CLASS: L<ViroDB::Result>

=cut

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'ViroDB::Result';

=head1 TABLE: C<viroserve.extraction>

=cut

__PACKAGE__->table("viroserve.extraction");

=head1 ACCESSORS

=head2 extraction_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'viroserve.extraction_extraction_id_seq'

=head2 sample_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 scientist_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 notes

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 protocol_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 amount

  data_type: 'double precision'
  is_nullable: 1

=head2 unit_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 date_entered

  data_type: 'date'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=head2 date_completed

  data_type: 'date'
  is_nullable: 1

=head2 extract_type_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 concentrated

  data_type: 'boolean'
  is_nullable: 1

=head2 vv_uid

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'viroserve.vv_uid'

=head2 concentration

  data_type: 'double precision'
  is_nullable: 1

=head2 concentration_unit_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 eluted_vol

  data_type: 'double precision'
  is_nullable: 1

=head2 eluted_vol_unit_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "extraction_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "viroserve.extraction_extraction_id_seq",
  },
  "sample_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "scientist_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "notes",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "protocol_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "amount",
  { data_type => "double precision", is_nullable => 1 },
  "unit_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "date_entered",
  {
    data_type     => "date",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "date_completed",
  { data_type => "date", is_nullable => 1 },
  "extract_type_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "concentrated",
  { data_type => "boolean", is_nullable => 1 },
  "vv_uid",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "viroserve.vv_uid",
  },
  "concentration",
  { data_type => "double precision", is_nullable => 1 },
  "concentration_unit_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "eluted_vol",
  { data_type => "double precision", is_nullable => 1 },
  "eluted_vol_unit_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</extraction_id>

=back

=cut

__PACKAGE__->set_primary_key("extraction_id");

=head1 RELATIONS

=head2 bisulfite_converted_dnas

Type: has_many

Related object: L<ViroDB::Result::BisulfiteConvertedDNA>

=cut

__PACKAGE__->has_many(
  "bisulfite_converted_dnas",
  "ViroDB::Result::BisulfiteConvertedDNA",
  { "foreign.extraction_id" => "self.extraction_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 concentration_unit

Type: belongs_to

Related object: L<ViroDB::Result::Unit>

=cut

__PACKAGE__->belongs_to(
  "concentration_unit",
  "ViroDB::Result::Unit",
  { unit_id => "concentration_unit_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 copy_numbers

Type: has_many

Related object: L<ViroDB::Result::CopyNumber>

=cut

__PACKAGE__->has_many(
  "copy_numbers",
  "ViroDB::Result::CopyNumber",
  { "foreign.extraction_id" => "self.extraction_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 eluted_vol_unit

Type: belongs_to

Related object: L<ViroDB::Result::Unit>

=cut

__PACKAGE__->belongs_to(
  "eluted_vol_unit",
  "ViroDB::Result::Unit",
  { unit_id => "eluted_vol_unit_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 extract_type

Type: belongs_to

Related object: L<ViroDB::Result::ExtractionType>

=cut

__PACKAGE__->belongs_to(
  "extract_type",
  "ViroDB::Result::ExtractionType",
  { extract_type_id => "extract_type_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 pcr_templates

Type: has_many

Related object: L<ViroDB::Result::PolymeraseChainReactionTemplate>

=cut

__PACKAGE__->has_many(
  "pcr_templates",
  "ViroDB::Result::PolymeraseChainReactionTemplate",
  { "foreign.extraction_id" => "self.extraction_id" },
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

=head2 rt_products

Type: has_many

Related object: L<ViroDB::Result::ReverseTranscriptionProduct>

=cut

__PACKAGE__->has_many(
  "rt_products",
  "ViroDB::Result::ReverseTranscriptionProduct",
  { "foreign.extraction_id" => "self.extraction_id" },
  { cascade_copy => 0, cascade_delete => 0 },
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

=head2 unit

Type: belongs_to

Related object: L<ViroDB::Result::Unit>

=cut

__PACKAGE__->belongs_to(
  "unit",
  "ViroDB::Result::Unit",
  { unit_id => "unit_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2019-04-08 14:52:37
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:v8VdXgkjOVWgJlxnzLT1yQ

use Hash::Merge qw< merge >;

with 'ViroDB::Role::HasCopyNumberSummary';

sub input_product { return $_[0]->sample; }
with "Viroverse::Model::Role::MolecularProduct";

sub copy_number_summary_of_rts {
    my $self = shift;
    my %merged;
    for my $rt ($self->rt_products) {
        my $next = $rt->copy_number_summary;
        %merged  = %{ merge(\%merged, $next) };
    }
    return \%merged;
}

__PACKAGE__->meta->make_immutable;
1;
