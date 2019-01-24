use utf8;
package ViroDB::Result::NucleicAcidSequenceLatestRevision;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ViroDB::Result::NucleicAcidSequenceLatestRevision

=cut

use strict;
use warnings;

=head1 BASE CLASS: L<ViroDB::Result>

=cut

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'ViroDB::Result';
__PACKAGE__->table_class("DBIx::Class::ResultSource::View");

=head1 TABLE: C<viroserve.na_sequence_latest_revision>

=cut

__PACKAGE__->table("viroserve.na_sequence_latest_revision");

=head1 ACCESSORS

=head2 na_sequence_id

  data_type: 'integer'
  is_nullable: 1

=head2 na_sequence_revision

  data_type: 'smallint'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "na_sequence_id",
  { data_type => "integer", is_nullable => 1 },
  "na_sequence_revision",
  { data_type => "smallint", is_nullable => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2017-08-11 15:11:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:3VmAQKd7Kh1vO/I+SVDX/w

__PACKAGE__->add_unique_constraint(["na_sequence_id"]);

sub idrev {
    my $self = shift;
    return join ".", ($self->na_sequence_id, $self->na_sequence_revision);
}

__PACKAGE__->meta->make_immutable;
1;
