use utf8;
package ViroDB::Result::DistinctSampleSearch;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ViroDB::Result::DistinctSampleSearch

=cut

use strict;
use warnings;

=head1 BASE CLASS: L<ViroDB::Result>

=cut

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'ViroDB::Result';

=head1 COMPONENTS LOADED

=over 4

=item * L<ViroDB::InflateColumn::JSON>

=back

=cut

__PACKAGE__->load_components("+ViroDB::InflateColumn::JSON");

=head1 TABLE: C<viroserve.distinct_sample_search>

=cut

__PACKAGE__->table("viroserve.distinct_sample_search");

=head1 ACCESSORS

=head2 sample_id

  data_type: 'integer'
  is_nullable: 1

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 25

=head2 tissue_type

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 tissue_type_id

  data_type: 'integer'
  is_nullable: 1

=head2 na_type

  data_type: 'text'
  is_nullable: 1

=head2 sample_date

  data_type: 'date'
  is_nullable: 1

=head2 derivation_protocol

  data_type: 'text'
  is_nullable: 1

=head2 derivation_protocol_id

  data_type: 'integer'
  is_nullable: 1

=head2 derivation_id

  data_type: 'integer'
  is_nullable: 1

=head2 patient

  data_type: 'text'
  is_nullable: 1

=head2 patient_id

  data_type: 'integer'
  is_nullable: 1

=head2 viral_load

  data_type: 'numeric'
  is_nullable: 1

=head2 viral_load_limit_of_quantification

  data_type: 'integer'
  is_nullable: 1

=head2 available_aliquots

  data_type: 'bigint'
  is_nullable: 1

=head2 has_sequences

  data_type: 'boolean'
  is_nullable: 1

=head2 cohorts

  data_type: 'character varying[]'
  is_nullable: 1

=head2 assignments

  data_type: 'jsonb'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "sample_id",
  { data_type => "integer", is_nullable => 1 },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 25 },
  "tissue_type",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "tissue_type_id",
  { data_type => "integer", is_nullable => 1 },
  "na_type",
  { data_type => "text", is_nullable => 1 },
  "sample_date",
  { data_type => "date", is_nullable => 1 },
  "derivation_protocol",
  { data_type => "text", is_nullable => 1 },
  "derivation_protocol_id",
  { data_type => "integer", is_nullable => 1 },
  "derivation_id",
  { data_type => "integer", is_nullable => 1 },
  "patient",
  { data_type => "text", is_nullable => 1 },
  "patient_id",
  { data_type => "integer", is_nullable => 1 },
  "viral_load",
  { data_type => "numeric", is_nullable => 1 },
  "viral_load_limit_of_quantification",
  { data_type => "integer", is_nullable => 1 },
  "available_aliquots",
  { data_type => "bigint", is_nullable => 1 },
  "has_sequences",
  { data_type => "boolean", is_nullable => 1 },
  "cohorts",
  { data_type => "character varying[]", is_nullable => 1 },
  "assignments",
  { data_type => "jsonb", is_nullable => 1 },
);

=head1 UNIQUE CONSTRAINTS

=head2 C<distinct_sample_search_sample_id_idx>

=over 4

=item * L</sample_id>

=back

=cut

__PACKAGE__->add_unique_constraint("distinct_sample_search_sample_id_idx", ["sample_id"]);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2017-09-15 15:28:22
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:u9fDqxKbNCcofXcTn204jw

use strict;
use warnings;
use 5.018;
use Viroverse::DateCensor;

sub as_hash {
    my $self = shift;

    my $patient = $self->result_source->schema->resultset("Patient")
        ->find($self->get_column('patient_id'));
    my $censor = Viroverse::DateCensor->new({ patient => $patient, censor => 1, });

    return {
        %{ $self->next::method(@_) },

        # Serialize the data structure, not the JSON text
        assignments        => $self->assignments,
        available_aliquots => defined $self->get_column('available_aliquots') ?
                                0+$self->get_column('available_aliquots') :
                                undef,
        viral_load => defined $self->get_column('viral_load') ?
                                0+$self->get_column('viral_load') :
                                undef,
        relative_date => $censor->represent_date($self->sample_date),

    };
}

__PACKAGE__->meta->make_immutable;
1;
