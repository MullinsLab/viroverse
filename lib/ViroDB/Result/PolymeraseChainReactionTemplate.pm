use utf8;
package ViroDB::Result::PolymeraseChainReactionTemplate;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ViroDB::Result::PolymeraseChainReactionTemplate

=cut

use strict;
use warnings;

=head1 BASE CLASS: L<ViroDB::Result>

=cut

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'ViroDB::Result';

=head1 TABLE: C<viroserve.pcr_template>

=cut

__PACKAGE__->table("viroserve.pcr_template");

=head1 ACCESSORS

=head2 pcr_template_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'viroserve.pcr_template_pcr_template_id_seq'

=head2 scientist_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 volume

  data_type: 'double precision'
  is_nullable: 1

=head2 unit_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 date_completed

  data_type: 'date'
  is_nullable: 0

=head2 date_entered

  data_type: 'date'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=head2 vv_uid

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'viroserve.vv_uid'

=head2 rt_product_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 extraction_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 pcr_product_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 dil_factor

  data_type: 'double precision'
  is_nullable: 1

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
  "pcr_template_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "viroserve.pcr_template_pcr_template_id_seq",
  },
  "scientist_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "volume",
  { data_type => "double precision", is_nullable => 1 },
  "unit_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "date_completed",
  { data_type => "date", is_nullable => 0 },
  "date_entered",
  {
    data_type     => "date",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "vv_uid",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "viroserve.vv_uid",
  },
  "rt_product_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "extraction_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "pcr_product_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "dil_factor",
  { data_type => "double precision", is_nullable => 1 },
  "sample_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "bisulfite_converted_dna_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</pcr_template_id>

=back

=cut

__PACKAGE__->set_primary_key("pcr_template_id");

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

=head2 pcr_product

Type: belongs_to

Related object: L<ViroDB::Result::PolymeraseChainReactionProduct>

=cut

__PACKAGE__->belongs_to(
  "pcr_product",
  "ViroDB::Result::PolymeraseChainReactionProduct",
  { pcr_product_id => "pcr_product_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 pcr_products

Type: has_many

Related object: L<ViroDB::Result::PolymeraseChainReactionProduct>

=cut

__PACKAGE__->has_many(
  "pcr_products",
  "ViroDB::Result::PolymeraseChainReactionProduct",
  { "foreign.pcr_template_id" => "self.pcr_template_id" },
  { cascade_copy => 0, cascade_delete => 0 },
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
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
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
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:aCwbV74FwiG54Lyx9Jz19A

use 5.018;
use warnings;
use strict;

use Viroverse::Logger qw< :log :dlog >;
use List::Util qw< any >;

# Override the constructor to rewrite "input_product" key in options to the
# foreign key column for the input product type. It'd be more robust to implement
# a Moose role (see Viroverse::Model::Role::MolecularProduct for a comparable
# widget) but for now this is concise and self-contained.
sub new {
    my ($class, $attrs) = @_;

    if (my $input = delete $attrs->{input_product}) {
        my ($pk) = $input->result_source->primary_columns;
        die "Unexpected foreign key name: $pk"
            unless any { $_ eq $pk }
                qw[ sample_id pcr_product_id rt_product_id
                    extraction_id bisulfite_converted_dna_id ];
        $attrs->{$pk} = $input->id;
    }

    my $new = $class->next::method($attrs);
    return $new;
}

sub input_product {
    my $self = shift;
    return $self->rt_product || $self->extraction || $self->pcr_product ||
           $self->sample     || $self->bisulfite_converted_dna;
}
with "Viroverse::Model::Role::MolecularProduct";

__PACKAGE__->meta->make_immutable(inline_constructor => 0);
1;
