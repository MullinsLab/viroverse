use utf8;
package ViroDB::Result::Derivation;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ViroDB::Result::Derivation

=cut

use strict;
use warnings;

=head1 BASE CLASS: L<ViroDB::Result>

=cut

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'ViroDB::Result';

=head1 TABLE: C<viroserve.derivation>

=cut

__PACKAGE__->table("viroserve.derivation");

=head1 ACCESSORS

=head2 derivation_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'viroserve.derivation_derivation_id_seq'

=head2 derivation_protocol_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 input_sample_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 uri

  data_type: 'text'
  is_nullable: 1

=head2 date_completed

  data_type: 'date'
  is_nullable: 0

=head2 scientist_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "derivation_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "viroserve.derivation_derivation_id_seq",
  },
  "derivation_protocol_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "input_sample_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "uri",
  { data_type => "text", is_nullable => 1 },
  "date_completed",
  { data_type => "date", is_nullable => 0 },
  "scientist_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</derivation_id>

=back

=cut

__PACKAGE__->set_primary_key("derivation_id");

=head1 RELATIONS

=head2 input_sample

Type: belongs_to

Related object: L<ViroDB::Result::Sample>

=cut

__PACKAGE__->belongs_to(
  "input_sample",
  "ViroDB::Result::Sample",
  { sample_id => "input_sample_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 output_samples

Type: has_many

Related object: L<ViroDB::Result::Sample>

=cut

__PACKAGE__->has_many(
  "output_samples",
  "ViroDB::Result::Sample",
  { "foreign.derivation_id" => "self.derivation_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 protocol

Type: belongs_to

Related object: L<ViroDB::Result::DerivationProtocol>

=cut

__PACKAGE__->belongs_to(
  "protocol",
  "ViroDB::Result::DerivationProtocol",
  { derivation_protocol_id => "derivation_protocol_id" },
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


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2019-04-30 16:05:40
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:6e18l3Z+H+V0QFiVx8gMlg

with 'Viroverse::SampleTree::Node';

sub primogenitor {
    my $self = shift;
    return $self->input_sample->primogenitor;
}

sub parent {
    my $self = shift;
    return $self->input_sample;
}

sub children {
    my $self = shift;
    return $self->output_samples
        ->search({}, { order_by => ["name", "date_collected"] });
}

__PACKAGE__->meta->make_immutable;
1;
