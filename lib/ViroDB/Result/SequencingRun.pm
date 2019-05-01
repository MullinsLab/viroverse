use utf8;
package ViroDB::Result::SequencingRun;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ViroDB::Result::SequencingRun

=cut

use strict;
use warnings;

=head1 BASE CLASS: L<ViroDB::Result>

=cut

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'ViroDB::Result';

=head1 TABLE: C<viroserve.sequencing_run>

=cut

__PACKAGE__->table("viroserve.sequencing_run");

=head1 ACCESSORS

=head2 sequencing_run_id

  data_type: 'integer'
  is_nullable: 0

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 note

  data_type: 'text'
  is_nullable: 1

=head2 scientist_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 date_submitted

  data_type: 'date'
  is_nullable: 1

=head2 date_completed

  data_type: 'date'
  is_nullable: 1

=head2 date_entered

  data_type: 'date'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "sequencing_run_id",
  { data_type => "integer", is_nullable => 0 },
  "name",
  { data_type => "text", is_nullable => 0 },
  "note",
  { data_type => "text", is_nullable => 1 },
  "scientist_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "date_submitted",
  { data_type => "date", is_nullable => 1 },
  "date_completed",
  { data_type => "date", is_nullable => 1 },
  "date_entered",
  { data_type => "date", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</sequencing_run_id>

=back

=cut

__PACKAGE__->set_primary_key("sequencing_run_id");

=head1 RELATIONS

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

=head2 sequencing_run_pcr_products

Type: has_many

Related object: L<ViroDB::Result::SequencingRunPolymeraseChainReactionProduct>

=cut

__PACKAGE__->has_many(
  "sequencing_run_pcr_products",
  "ViroDB::Result::SequencingRunPolymeraseChainReactionProduct",
  { "foreign.sequencing_run_id" => "self.sequencing_run_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2019-04-30 17:16:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:OuU7frQPKDRnJV4PKmBcng


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
