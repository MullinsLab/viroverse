use utf8;
package ViroDB::Result::SequenceSearch;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ViroDB::Result::SequenceSearch

=cut

use strict;
use warnings;

=head1 BASE CLASS: L<ViroDB::Result>

=cut

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'ViroDB::Result';

=head1 TABLE: C<viroserve.sequence_search>

=cut

__PACKAGE__->table("viroserve.sequence_search");

=head1 ACCESSORS

=head2 na_sequence_id

  data_type: 'integer'
  is_nullable: 1

=head2 na_sequence_revision

  data_type: 'integer'
  is_nullable: 1

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 na_type

  data_type: 'viroserve.na_type'
  is_nullable: 1

=head2 entered_date

  data_type: 'date'
  is_nullable: 1

=head2 tissue_type

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 tissue_type_id

  data_type: 'integer'
  is_nullable: 1

=head2 scientist

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 scientist_id

  data_type: 'integer'
  is_nullable: 1

=head2 pcr_name

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 sample_name

  data_type: 'varchar'
  is_nullable: 1
  size: 25

=head2 sample_id

  data_type: 'integer'
  is_nullable: 1

=head2 patient

  data_type: 'text'
  is_nullable: 1

=head2 patient_id

  data_type: 'integer'
  is_nullable: 1

=head2 type

  data_type: 'text'
  is_nullable: 1

=head2 cohorts

  data_type: 'character varying[]'
  is_nullable: 1

=head2 regions

  data_type: 'text[]'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "na_sequence_id",
  { data_type => "integer", is_nullable => 1 },
  "na_sequence_revision",
  { data_type => "integer", is_nullable => 1 },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "na_type",
  { data_type => "viroserve.na_type", is_nullable => 1 },
  "entered_date",
  { data_type => "date", is_nullable => 1 },
  "tissue_type",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "tissue_type_id",
  { data_type => "integer", is_nullable => 1 },
  "scientist",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "scientist_id",
  { data_type => "integer", is_nullable => 1 },
  "pcr_name",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "sample_name",
  { data_type => "varchar", is_nullable => 1, size => 25 },
  "sample_id",
  { data_type => "integer", is_nullable => 1 },
  "patient",
  { data_type => "text", is_nullable => 1 },
  "patient_id",
  { data_type => "integer", is_nullable => 1 },
  "type",
  { data_type => "text", is_nullable => 1 },
  "cohorts",
  { data_type => "character varying[]", is_nullable => 1 },
  "regions",
  { data_type => "text[]", is_nullable => 1 },
);

=head1 UNIQUE CONSTRAINTS

=head2 C<sequence_search_na_sequence_id_idx>

=over 4

=item * L</na_sequence_id>

=back

=cut

__PACKAGE__->add_unique_constraint("sequence_search_na_sequence_id_idx", ["na_sequence_id"]);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2018-03-13 13:18:31
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:VQHFODfcwGeK2mOcKiJHoQ


sub accession {
    my $self = shift;

    # This may be true when we're aggregating sequence results…
    return undef if not defined $self->na_sequence_id;

    # …but usually it's not!
    return join ".",
        $self->na_sequence_id,
        $self->na_sequence_revision;
}

sub as_hash {
    my $self = shift;
    my $hash = $self->next::method;
    $hash->{accession} = $self->accession
        if $self->accession;
    return $hash;
}

__PACKAGE__->meta->make_immutable;
1;
