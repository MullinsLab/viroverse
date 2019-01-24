use utf8;
package ViroDB::Result::Aliquot;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ViroDB::Result::Aliquot

=cut

use strict;
use warnings;

=head1 BASE CLASS: L<ViroDB::Result>

=cut

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'ViroDB::Result';

=head1 TABLE: C<viroserve.aliquot>

=cut

__PACKAGE__->table("viroserve.aliquot");

=head1 ACCESSORS

=head2 aliquot_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'viroserve.aliquot_aliquot_id_seq'

=head2 sample_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 vol

  data_type: 'numeric'
  is_nullable: 1

=head2 unit_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 creating_scientist_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 possessing_scientist_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 manifest_id

  data_type: 'integer'
  is_nullable: 1

=head2 orphaned

  data_type: 'date'
  is_nullable: 1

=head2 num_thaws

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 date_entered

  data_type: 'date'
  default_value: current_timestamp
  is_nullable: 1
  original: {default_value => \"now()"}

=head2 received_date

  data_type: 'date'
  is_nullable: 1

=head2 vv_uid

  data_type: 'bigint'
  is_auto_increment: 1
  is_nullable: 1
  sequence: 'viroserve.vv_uid'

=head2 qc_d

  data_type: 'boolean'
  default_value: false
  is_nullable: 1

=head2 is_deleted

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "aliquot_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "viroserve.aliquot_aliquot_id_seq",
  },
  "sample_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "vol",
  { data_type => "numeric", is_nullable => 1 },
  "unit_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "creating_scientist_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "possessing_scientist_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "manifest_id",
  { data_type => "integer", is_nullable => 1 },
  "orphaned",
  { data_type => "date", is_nullable => 1 },
  "num_thaws",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "date_entered",
  {
    data_type     => "date",
    default_value => \"current_timestamp",
    is_nullable   => 1,
    original      => { default_value => \"now()" },
  },
  "received_date",
  { data_type => "date", is_nullable => 1 },
  "vv_uid",
  {
    data_type         => "bigint",
    is_auto_increment => 1,
    is_nullable       => 1,
    sequence          => "viroserve.vv_uid",
  },
  "qc_d",
  { data_type => "boolean", default_value => \"false", is_nullable => 1 },
  "is_deleted",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</aliquot_id>

=back

=cut

__PACKAGE__->set_primary_key("aliquot_id");

=head1 RELATIONS

=head2 box_pos

Type: might_have

Related object: L<ViroDB::Result::BoxPos>

=cut

__PACKAGE__->might_have(
  "box_pos",
  "ViroDB::Result::BoxPos",
  { "foreign.aliquot_id" => "self.aliquot_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 creating_scientist

Type: belongs_to

Related object: L<ViroDB::Result::Scientist>

=cut

__PACKAGE__->belongs_to(
  "creating_scientist",
  "ViroDB::Result::Scientist",
  { scientist_id => "creating_scientist_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 possessing_scientist

Type: belongs_to

Related object: L<ViroDB::Result::Scientist>

=cut

__PACKAGE__->belongs_to(
  "possessing_scientist",
  "ViroDB::Result::Scientist",
  { scientist_id => "possessing_scientist_id" },
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
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 unit

Type: belongs_to

Related object: L<ViroDB::Result::Unit>

=cut

__PACKAGE__->belongs_to(
  "unit",
  "ViroDB::Result::Unit",
  { unit_id => "unit_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2017-08-11 15:11:37
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:5Y0Ho3OkpMwMXbKz+oRQ1g

sub is_in_freezer {
    my ($self) = shift;
    return !!$self->box_pos;
}

sub status {
    my $self = shift;
    if ($self->is_in_freezer){
        return 'Reserved' if $self->possessing_scientist_id;
        return 'In freezer (' . ($self->qc_d ? q{} : 'not ') . 'qc\'d)';
    }

     return 'Handed Out' if $self->possessing_scientist_id;
     return 'Lost'       if $self->orphaned;
     return 'Unknown';
}

__PACKAGE__->meta->make_immutable;
1;
