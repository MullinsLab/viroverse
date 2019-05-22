use utf8;
package ViroDB::Result::NucleicAcidSequence;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ViroDB::Result::NucleicAcidSequence

=cut

use strict;
use warnings;

=head1 BASE CLASS: L<ViroDB::Result>

=cut

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'ViroDB::Result';

=head1 TABLE: C<viroserve.na_sequence>

=cut

__PACKAGE__->table("viroserve.na_sequence");

=head1 ACCESSORS

=head2 na_sequence_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'viroserve.na_sequence_na_sequence_id_seq'

=head2 na_sequence_revision

  data_type: 'smallint'
  default_value: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 sequence

  accessor: 'sequence_bases'
  data_type: 'text'
  is_nullable: 0

=head2 entered_date

  data_type: 'date'
  default_value: ('now'::text)::date
  is_nullable: 1

=head2 trimmed

  data_type: 'boolean'
  is_nullable: 1

=head2 note

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 scientist_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 pcr_product_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 clone_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 sample_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 genbank_acc

  data_type: 'varchar'
  is_nullable: 1
  size: 8

=head2 deleted

  data_type: 'boolean'
  is_nullable: 1

=head2 vv_uid

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'viroserve.vv_uid'

=head2 na_type

  data_type: 'viroserve.na_type'
  is_nullable: 1

=head2 sequence_type_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "na_sequence_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "viroserve.na_sequence_na_sequence_id_seq",
  },
  "na_sequence_revision",
  { data_type => "smallint", default_value => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "sequence",
  { accessor => "sequence_bases", data_type => "text", is_nullable => 0 },
  "entered_date",
  {
    data_type     => "date",
    default_value => \"('now'::text)::date",
    is_nullable   => 1,
  },
  "trimmed",
  { data_type => "boolean", is_nullable => 1 },
  "note",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "scientist_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "pcr_product_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "clone_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "sample_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "genbank_acc",
  { data_type => "varchar", is_nullable => 1, size => 8 },
  "deleted",
  { data_type => "boolean", is_nullable => 1 },
  "vv_uid",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "viroserve.vv_uid",
  },
  "na_type",
  { data_type => "viroserve.na_type", is_nullable => 1 },
  "sequence_type_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</na_sequence_id>

=item * L</na_sequence_revision>

=back

=cut

__PACKAGE__->set_primary_key("na_sequence_id", "na_sequence_revision");

=head1 RELATIONS

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

=head2 sequence_chromats

Type: has_many

Related object: L<ViroDB::Result::SequenceChromat>

=cut

__PACKAGE__->has_many(
  "sequence_chromats",
  "ViroDB::Result::SequenceChromat",
  {
    "foreign.na_sequence_id"       => "self.na_sequence_id",
    "foreign.na_sequence_revision" => "self.na_sequence_revision",
  },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 type

Type: belongs_to

Related object: L<ViroDB::Result::SequenceType>

=cut

__PACKAGE__->belongs_to(
  "type",
  "ViroDB::Result::SequenceType",
  { sequence_type_id => "sequence_type_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2018-03-13 13:18:31
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:IJMiKJr+JBV1odQHhd6SZw

use List::Util 1.33 qw< any >;
use Viroverse::Types -types;

__PACKAGE__->many_to_many("chromats", "sequence_chromats", "chromat");

__PACKAGE__->belongs_to(
  "latest_revision",
  "ViroDB::Result::NucleicAcidSequenceLatestRevision",
  { "foreign.na_sequence_id" => "self.na_sequence_id", "foreign.na_sequence_revision" => "self.na_sequence_revision" }
);

# Like latest_revision above, but as a LEFT JOIN so that it can be used more
# broadly for some searches.  This should probably only be used sparingly.
__PACKAGE__->belongs_to(
  "maybe_latest_revision",
  "ViroDB::Result::NucleicAcidSequenceLatestRevision",
  {
      "foreign.na_sequence_id"       => "self.na_sequence_id",
      "foreign.na_sequence_revision" => "self.na_sequence_revision"
  },
  {
      is_deferrable => 0,
      join_type     => "LEFT",
      on_delete     => "NO ACTION",
      on_update     => "NO ACTION",
  },
);

=head1 METHODS

=head2 insert

Strips spaces from sequences contents before inserting to database.

=cut

sub insert {
    my ($self, @args) = @_;

    # strip spaces from sequence contents
    $self->sequence($self->sequence =~ s/\s//gur);
    return $self->next::method(@args);
}

=head2 create_revision

Takes a hashref of field values to be used in a new revision of the current
sequence object. The current sequence is used to provide defaults for missing
values which generally remain the same across revisions. The two primary key
fields are added and revision is bumped by 1 from the current object's
revision. Creates, persists, and returns a new sequence.

B<A note on transactional integrity>: It's possible that other code will insert
a new revision for the same sequence between your code calling this method and
inserting your new revision.  In this case, the insert will fail due to the
primary key constraints on (id, rev).  Should this occur, you B<must> reload
your sequence object by id to get the latest revision and call this method
again before reattempting the insert.

There is still the chance of a race condition producing stale data in your new
revision if code is updating sequences without creating a new revision.  To
avoid this, you can wrap your code in a database transaction which does a
C<SELECT FOR UPDATE> on all revisions of the id.

Port (with different semantics) of L<Viroverse::Model::sequence::dna/new_revision>.

=cut


sub create_revision {
    my $self = shift;
    my $data = shift || {};

    unless ($self->in_storage) {
        die "create_revision called on un-persisted sequence object!";
    }

    my @new_revision_defaults = qw(
        scientist_id
        name
        sequence
        trimmed
        deleted
        note
        pcr_product_id
        clone_id
        sample_id
        sequence_type_id
        na_type
    );

    return undef unless any { $self->get_column($_) ne $data->{$_} } keys %$data;

    my %cols = $self->get_columns;
    my %column_values_from_parent;
    @column_values_from_parent{@new_revision_defaults} = @cols{@new_revision_defaults};

    # Adding 1 to the revision here is ~okay because any attempted INSERT will
    # fail if the (id, rev) pair already exists thanks to database the PK
    # constraint.  We'd rather it fail since the rest of the sequence data
    # (i.e. NewRevisionDefaults) is also cached outside a transaction and may
    # be stale.  See the method doc above.
    #
    # Any solution that makes the next revision always correct at time of
    # INSERT should also make all the other columns always correct as well.
    # -trs, 18 April 2014 (in Viroverse::Model::sequence::dna)
    my $new_revision = $self->result_source->schema->resultset('NucleicAcidSequence')->create({
        # Defaults from current revision
        %column_values_from_parent,

        # New revision
        %$data,

        # PKs for new revision
        na_sequence_id       => $self->na_sequence_id,
        na_sequence_revision => $self->na_sequence_revision + 1,
    });
    $new_revision->set_chromats($self->chromats) if $self->chromats->count;
    return $new_revision;
}

=head2 scientist_can_revise

Given a L<ViroDB::Result::Scientist>, returns a boolean indicating if the
scientist may revise this sequence or not.

=cut

sub scientist_can_revise {
    my $self = shift;
    my $sci  = shift;
    (ViroDBRecord["Scientist"])->assert_valid($sci);
    return $sci->can_edit && (
        $sci->is_supervisor || $sci->is_admin || ($sci->id == $self->scientist_id)
    );
}

sub idrev {
    my $self = shift;
    return join ".", ($self->na_sequence_id, $self->na_sequence_revision);
}

sub parent_revision {
    my $self = shift;
    return if $self->na_sequence_revision == 1;
    return $self->result_source->schema->resultset("NucleicAcidSequence")
        ->search(
            {
                na_sequence_id       =>       $self->na_sequence_id,
                na_sequence_revision => {'<', $self->na_sequence_revision}
            },
            {
                order_by      => ['na_sequence_revision desc'],
                limit         => 1,
            }
        )->first;
}

sub has_revisions {
    my $self = shift;
    return $self->result_source->schema->resultset("NucleicAcidSequence")
                ->search({
                    na_sequence_id => $self->na_sequence_id,
                    na_sequence_revision => {'>', 1 }
                })->has_rows;
}

__PACKAGE__->meta->make_immutable;
1;
