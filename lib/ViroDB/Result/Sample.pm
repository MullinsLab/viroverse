use utf8;
package ViroDB::Result::Sample;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ViroDB::Result::Sample

=cut

use strict;
use warnings;

=head1 BASE CLASS: L<ViroDB::Result>

=cut

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'ViroDB::Result';

=head1 TABLE: C<viroserve.sample>

=cut

__PACKAGE__->table("viroserve.sample");

=head1 ACCESSORS

=head2 sample_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'viroserve.sample_sample_id_seq'

=head2 sample_type_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 tissue_type_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 received_date

  data_type: 'date'
  is_nullable: 1

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 25

=head2 visit_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 vv_uid

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'viroserve.vv_uid'

=head2 date_added

  data_type: 'date'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=head2 additive_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 is_deleted

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 derivation_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 date_collected

  data_type: 'date'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "sample_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "viroserve.sample_sample_id_seq",
  },
  "sample_type_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "tissue_type_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "received_date",
  { data_type => "date", is_nullable => 1 },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 25 },
  "visit_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
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
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "additive_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "is_deleted",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "derivation_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "date_collected",
  { data_type => "date", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</sample_id>

=back

=cut

__PACKAGE__->set_primary_key("sample_id");

=head1 RELATIONS

=head2 additive

Type: belongs_to

Related object: L<ViroDB::Result::Additive>

=cut

__PACKAGE__->belongs_to(
  "additive",
  "ViroDB::Result::Additive",
  { additive_id => "additive_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 aliquots

Type: has_many

Related object: L<ViroDB::Result::Aliquot>

=cut

__PACKAGE__->has_many(
  "aliquots",
  "ViroDB::Result::Aliquot",
  { "foreign.sample_id" => "self.sample_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 bisulfite_converted_dnas

Type: has_many

Related object: L<ViroDB::Result::BisulfiteConvertedDNA>

=cut

__PACKAGE__->has_many(
  "bisulfite_converted_dnas",
  "ViroDB::Result::BisulfiteConvertedDNA",
  { "foreign.sample_id" => "self.sample_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 categorical_lab_results

Type: has_many

Related object: L<ViroDB::Result::CategoricalLabResult>

=cut

__PACKAGE__->has_many(
  "categorical_lab_results",
  "ViroDB::Result::CategoricalLabResult",
  { "foreign.sample_id" => "self.sample_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 child_derivations

Type: has_many

Related object: L<ViroDB::Result::Derivation>

=cut

__PACKAGE__->has_many(
  "child_derivations",
  "ViroDB::Result::Derivation",
  { "foreign.input_sample_id" => "self.sample_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 copy_numbers

Type: has_many

Related object: L<ViroDB::Result::CopyNumber>

=cut

__PACKAGE__->has_many(
  "copy_numbers",
  "ViroDB::Result::CopyNumber",
  { "foreign.sample_id" => "self.sample_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 extractions

Type: has_many

Related object: L<ViroDB::Result::Extraction>

=cut

__PACKAGE__->has_many(
  "extractions",
  "ViroDB::Result::Extraction",
  { "foreign.sample_id" => "self.sample_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 na_sequences

Type: has_many

Related object: L<ViroDB::Result::NucleicAcidSequence>

=cut

__PACKAGE__->has_many(
  "na_sequences",
  "ViroDB::Result::NucleicAcidSequence",
  { "foreign.sample_id" => "self.sample_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 notes

Type: has_many

Related object: L<ViroDB::Result::SampleNote>

=cut

__PACKAGE__->has_many(
  "notes",
  "ViroDB::Result::SampleNote",
  { "foreign.sample_id" => "self.sample_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 numeric_lab_results

Type: has_many

Related object: L<ViroDB::Result::NumericLabResult>

=cut

__PACKAGE__->has_many(
  "numeric_lab_results",
  "ViroDB::Result::NumericLabResult",
  { "foreign.sample_id" => "self.sample_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 parent_derivation

Type: belongs_to

Related object: L<ViroDB::Result::Derivation>

=cut

__PACKAGE__->belongs_to(
  "parent_derivation",
  "ViroDB::Result::Derivation",
  { derivation_id => "derivation_id" },
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
  { "foreign.sample_id" => "self.sample_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 project_assignments

Type: has_many

Related object: L<ViroDB::Result::ProjectSample>

=cut

__PACKAGE__->has_many(
  "project_assignments",
  "ViroDB::Result::ProjectSample",
  { "foreign.sample_id" => "self.sample_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 sample_type

Type: belongs_to

Related object: L<ViroDB::Result::SampleType>

=cut

__PACKAGE__->belongs_to(
  "sample_type",
  "ViroDB::Result::SampleType",
  { sample_type_id => "sample_type_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 tissue_type

Type: belongs_to

Related object: L<ViroDB::Result::TissueType>

=cut

__PACKAGE__->belongs_to(
  "tissue_type",
  "ViroDB::Result::TissueType",
  { tissue_type_id => "tissue_type_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 visit

Type: belongs_to

Related object: L<ViroDB::Result::Visit>

=cut

__PACKAGE__->belongs_to(
  "visit",
  "ViroDB::Result::Visit",
  { visit_id => "visit_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2019-04-08 14:52:37
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:/+/breuzWIM4BVXhBTD1TA

with 'Viroverse::SampleTree::Node';

__PACKAGE__->belongs_to(
    "search_data",
    "ViroDB::Result::DistinctSampleSearch",
    { "foreign.sample_id" => "self.sample_id" },
);

__PACKAGE__->has_one(
    "patient_and_date",
    "ViroDB::Result::SamplePatientDate",
    { "foreign.sample_id" => "self.sample_id" },
    {
      is_deferrable => 0,
      join_type     => "LEFT",
      on_delete     => "NO ACTION",
      on_update     => "NO ACTION",
    },
);

sub derived_samples {
    my $self = shift;
    return $self->child_derivations->search_related('output_samples', {}, {order_by => {-asc => 'name'}});
}

sub pcr_products {
    my $self = shift;
    return $self->result_source->schema->resultset('SamplePcrDescendant')
        ->search({ }, { bind => [ $self->id ] })
        ->related_resultset('pcr_product');
}

=head2 ice_cultures

This wraps up a somewhat tortured ORM query to get all the samples output from
an ICE culture derivation of a Resting or Total T cell output of a Negative
selection derivation that is a child of this sample. This facilitates building
a non-generic UX for descendant cultures that doesn't make the user walk
through resting/total CD4 samples themselves.

=cut

sub ice_cultures {
    my $self = shift;
    $self->child_derivations
    ->search_related(
        "output_samples",
        { "tissue_type.name" => [ "Resting CD4+ T cells", "Total CD4+ T cells" ] },
        { join => "tissue_type" },
    )
    ->search_related(
        "child_derivations",
        { "protocol.name" => "ICE culture" },
        { join => "protocol" },
    )
    ->search_related("output_samples",
        undef,
        {
            order_by => { -asc => "output_samples_2.name" },
        },
    );
}

sub date {
    my $self = shift;
    if ($self->date_collected) {
        return $self->date_collected;
    } elsif ($self->parent_derivation) {
        return $self->parent_derivation->date_completed;
    } elsif ($self->visit) {
        return $self->visit->visit_date;
    } else {
        return undef;
    }
}

sub patient {
    my $self = shift;
    if ($self->visit_id) {
        return $self->visit->patient;
    } elsif ($self->derivation_id) {
        return $self->parent_derivation->input_sample->patient;
    } else {
        return undef;
    }
}

sub give_id {
    my $self = shift;
    return $self->get_column('sample_id');
}

# In my view there's no reason for an object to know how to generate
# a particular human-readable name for itself based on components like
# this; templates should really use APIs directly to provide the best
# representation for their context. However, we're trying to cope with
# what already exists here so we reimplement the old-fashioned to_string
# here to contain scope slightly.
sub to_string {
    my $self = shift;
    return join ' ',(
        $self->name || '',
        $self->patient ? $self->patient->name : 'unknown patient',
        $self->date ? $self->date->strftime("%Y-%m-%d") : 'unknown date' ,
        $self->tissue_type ? $self->tissue_type->name : ''
    );
}

sub primogenitor {
    my $self = shift;
    return $self unless $self->parent_derivation;
    return $self->parent_derivation->primogenitor;
}

sub parent {
    my $self = shift;
    return $self->parent_derivation || $self->patient;
}

sub children {
    my $self = shift;
    return $self->child_derivations
        ->search({}, { order_by => "date_completed DESC" });
}

=head2 copy_numbers

Returns a list of L<Viroverse::Model::copy_number> objects relevant to this
sample (either by an RT product, extraction, bisulfite conversion, or direct
PCR).

=cut

sub copy_numbers {
    my $self = shift;
    require Viroverse::Model::copy_number;
    return Viroverse::Model::copy_number->search_by_sample($self->sample_id);
}

__PACKAGE__->meta->make_immutable;
1;
