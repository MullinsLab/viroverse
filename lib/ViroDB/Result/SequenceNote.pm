use utf8;
package ViroDB::Result::SequenceNote;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ViroDB::Result::SequenceNote

=cut

use strict;
use warnings;

=head1 BASE CLASS: L<ViroDB::Result>

=cut

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'ViroDB::Result';

=head1 TABLE: C<viroserve.na_sequence_note>

=cut

__PACKAGE__->table("viroserve.na_sequence_note");

=head1 ACCESSORS

=head2 na_sequence_note_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'viroserve.na_sequence_note_na_sequence_note_id_seq'

=head2 na_sequence_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 na_sequence_revision

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 scientist_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 body

  data_type: 'text'
  is_nullable: 0

=head2 time_created

  data_type: 'timestamp with time zone'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=cut

__PACKAGE__->add_columns(
  "na_sequence_note_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "viroserve.na_sequence_note_na_sequence_note_id_seq",
  },
  "na_sequence_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "na_sequence_revision",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "scientist_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "body",
  { data_type => "text", is_nullable => 0 },
  "time_created",
  {
    data_type     => "timestamp with time zone",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</na_sequence_note_id>

=back

=cut

__PACKAGE__->set_primary_key("na_sequence_note_id");

=head1 RELATIONS

=head2 na_sequence

Type: belongs_to

Related object: L<ViroDB::Result::NucleicAcidSequence>

=cut

__PACKAGE__->belongs_to(
  "na_sequence",
  "ViroDB::Result::NucleicAcidSequence",
  {
    na_sequence_id       => "na_sequence_id",
    na_sequence_revision => "na_sequence_revision",
  },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
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


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2019-05-23 13:47:19
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:JFFOrwsdRaD02lIj65v8PA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
