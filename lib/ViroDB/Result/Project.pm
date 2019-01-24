use utf8;
package ViroDB::Result::Project;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ViroDB::Result::Project

=cut

use strict;
use warnings;

=head1 BASE CLASS: L<ViroDB::Result>

=cut

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'ViroDB::Result';

=head1 TABLE: C<viroserve.project>

=cut

__PACKAGE__->table("viroserve.project");

=head1 ACCESSORS

=head2 project_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'viroserve.project_project_id_seq'

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 orig_scientist_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 start_date

  data_type: 'date'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=head2 completed_date

  data_type: 'date'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "project_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "viroserve.project_project_id_seq",
  },
  "name",
  { data_type => "text", is_nullable => 0 },
  "orig_scientist_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "start_date",
  {
    data_type     => "date",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "completed_date",
  { data_type => "date", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</project_id>

=back

=cut

__PACKAGE__->set_primary_key("project_id");

=head1 RELATIONS

=head2 sample_assignments

Type: has_many

Related object: L<ViroDB::Result::ProjectSample>

=cut

__PACKAGE__->has_many(
  "sample_assignments",
  "ViroDB::Result::ProjectSample",
  { "foreign.project_id" => "self.project_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 scientist

Type: belongs_to

Related object: L<ViroDB::Result::Scientist>

=cut

__PACKAGE__->belongs_to(
  "scientist",
  "ViroDB::Result::Scientist",
  { scientist_id => "orig_scientist_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2018-02-02 13:54:26
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:wZUdSUKmeqpx5iF1rFU56A

sub assign {
    my ($self, $sample, $scientist) = @_;
    my $existing_assignment = $self->sample_assignments->search({ sample_id => $sample->id })->single;
    if ($existing_assignment) {
        $existing_assignment->assigned_scientist($scientist);
        $existing_assignment->update;
    } else {
        $self->sample_assignments->create({
            sample => $sample,
            ($scientist
                ? (assigned_scientist => $scientist)
                : ()),
        });
    }
}

sub sequences {
  my $self = shift;
  my $sequences = $self->sample_assignments->search_related("sample")->search_related("na_sequences")->latest_revisions;
  return $sequences;
}

sub extractions {
  my $self = shift;
  my $extractions = $self->sample_assignments->search_related("sample")->search_related("extractions");
  return $extractions;
}

__PACKAGE__->meta->make_immutable;
1;
