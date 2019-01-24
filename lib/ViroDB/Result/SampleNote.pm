use utf8;
package ViroDB::Result::SampleNote;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ViroDB::Result::SampleNote

=cut

use strict;
use warnings;

=head1 BASE CLASS: L<ViroDB::Result>

=cut

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'ViroDB::Result';

=head1 TABLE: C<viroserve.sample_note>

=cut

__PACKAGE__->table("viroserve.sample_note");

=head1 ACCESSORS

=head2 note_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'viroserve.note_note_id_seq'

=head2 sample_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 body

  data_type: 'text'
  is_nullable: 0

=head2 scientist_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 time_created

  data_type: 'timestamp with time zone'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=cut

__PACKAGE__->add_columns(
  "note_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "viroserve.note_note_id_seq",
  },
  "sample_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "body",
  { data_type => "text", is_nullable => 0 },
  "scientist_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
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

=item * L</note_id>

=back

=cut

__PACKAGE__->set_primary_key("note_id");

=head1 RELATIONS

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


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2017-09-15 11:22:21
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:C0ZwDvV4gLc2juP1A1OOqA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
