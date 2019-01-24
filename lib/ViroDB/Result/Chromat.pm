use utf8;
package ViroDB::Result::Chromat;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ViroDB::Result::Chromat

=cut

use strict;
use warnings;

=head1 BASE CLASS: L<ViroDB::Result>

=cut

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'ViroDB::Result';

=head1 TABLE: C<viroserve.chromat>

=cut

__PACKAGE__->table("viroserve.chromat");

=head1 ACCESSORS

=head2 chromat_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'viroserve.chromat_chromat_id_seq'

=head2 vv_uid

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'viroserve.vv_uid'

=head2 date_entered

  data_type: 'date'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=head2 scientist_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 data

  data_type: 'bytea'
  is_nullable: 1

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 chromat_type_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 primer_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "chromat_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "viroserve.chromat_chromat_id_seq",
  },
  "vv_uid",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "viroserve.vv_uid",
  },
  "date_entered",
  {
    data_type     => "date",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "scientist_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "data",
  { data_type => "bytea", is_nullable => 1 },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "chromat_type_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "primer_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</chromat_id>

=back

=cut

__PACKAGE__->set_primary_key("chromat_id");

=head1 RELATIONS

=head2 chromat_na_sequences

Type: has_many

Related object: L<ViroDB::Result::SequenceChromat>

=cut

__PACKAGE__->has_many(
  "chromat_na_sequences",
  "ViroDB::Result::SequenceChromat",
  { "foreign.chromat_id" => "self.chromat_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 chromat_type

Type: belongs_to

Related object: L<ViroDB::Result::ChromatType>

=cut

__PACKAGE__->belongs_to(
  "chromat_type",
  "ViroDB::Result::ChromatType",
  { chromat_type_id => "chromat_type_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 primer

Type: belongs_to

Related object: L<ViroDB::Result::Primer>

=cut

__PACKAGE__->belongs_to(
  "primer",
  "ViroDB::Result::Primer",
  { primer_id => "primer_id" },
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


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2017-11-16 12:41:03
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:R3p5NLJoVYSKmmGtzT2MWw

no warnings 'experimental::regex_sets';

sub insert {
    my ($self, @args) = @_;
    $self->infer_chromat_type;
    $self->next::method(@args);
}

sub infer_chromat_type {
    my $self = shift;
    return if $self->chromat_type;

    my $type = $self->result_source->schema
        ->resultset("ChromatType")
        ->find_from_data( $self->data );

    die "Unrecognized chromat type for file " . $self->name
        unless $type;

    $self->chromat_type($type);
}

sub plausible_primer_regex {
    return qr/
        # The primary capture group containing the plausible primer name

        (
            # Non-greedily capture the letters, numbers, and punctuation
            # (excluding hyphens and underscores) leading up to the
            # file extension
            (?:
                (?[ [a-z0-9] + [[:punct:]] - [-_] ])+?
            )

            # Optional hyphen- or underscore-suffixed parts are
            # explicitly whitelisted as special cases…
            (?: [-_]
                (?: \d+     # …any number
                  | [FR]\d? # …a primer orientation F(orward) and R(everse), with optional number
                  | deg     # …deg(graded)
                  | alt\d*  # …an alt version
                  | M       # …an HIV clade
                )
            )?
        )
        # There might be a 96-well plate coordinate here, for chromats
        # sequenced by MCLab.
        (?:
            _[A-Z][01][0-9]
        )?
        # Match one or more extension anchored to the end of the filename
        (?: \.
            (?: SCF                      # Sequencher chromat files
              | ab1 (\s*\(reversed\))?)  # ABI chromat files…
                                         #   …to which some software (Geneious?)
                                         #    adds " (reversed)" when RC-ing‽
        )+$
    /ix;
}

sub plausible_primers {
    my $self = shift;
    return unless $self->name;
    # Chromat filenames are delimited between some sample name (contextually meaningful
    # to the scientist preparing plates for sequencing, probably includes a PCR nickname,
    # patient and tissue identifier, etc) and a primer name by a `-`. There's some weirdo
    # primer names in the database and we'll allow the whole set of ascii punctuation
    # except for `-` in the primer part.
    my ($primer_guess) = $self->name =~ $self->plausible_primer_regex;
    return $self->result_source->schema->resultset("Primer")->plausible_for($primer_guess);
}


__PACKAGE__->meta->make_immutable;
1;
