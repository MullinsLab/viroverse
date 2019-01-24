use utf8;
package ViroDB::Result::Box;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ViroDB::Result::Box

=cut

use strict;
use warnings;

=head1 BASE CLASS: L<ViroDB::Result>

=cut

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'ViroDB::Result';

=head1 TABLE: C<freezer.box>

=cut

__PACKAGE__->table("freezer.box");

=head1 ACCESSORS

=head2 box_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'freezer.box_box_id_seq'

=head2 rack_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 name

  data_type: 'text'
  is_nullable: 0
  original: {data_type => "varchar"}

=head2 order_key

  data_type: 'integer'
  is_nullable: 1

=head2 num_rows

  data_type: 'integer'
  default_value: 9
  is_nullable: 1

=head2 num_columns

  data_type: 'integer'
  default_value: 9
  is_nullable: 1

=head2 creating_scientist_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 owning_scientist_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "box_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "freezer.box_box_id_seq",
  },
  "rack_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "name",
  {
    data_type   => "text",
    is_nullable => 0,
    original    => { data_type => "varchar" },
  },
  "order_key",
  { data_type => "integer", is_nullable => 1 },
  "num_rows",
  { data_type => "integer", default_value => 9, is_nullable => 1 },
  "num_columns",
  { data_type => "integer", default_value => 9, is_nullable => 1 },
  "creating_scientist_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "owning_scientist_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</box_id>

=back

=cut

__PACKAGE__->set_primary_key("box_id");

=head1 RELATIONS

=head2 box_positions

Type: has_many

Related object: L<ViroDB::Result::BoxPos>

=cut

__PACKAGE__->has_many(
  "box_positions",
  "ViroDB::Result::BoxPos",
  { "foreign.box_id" => "self.box_id" },
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

=head2 owning_scientist

Type: belongs_to

Related object: L<ViroDB::Result::Scientist>

=cut

__PACKAGE__->belongs_to(
  "owning_scientist",
  "ViroDB::Result::Scientist",
  { scientist_id => "owning_scientist_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 rack

Type: belongs_to

Related object: L<ViroDB::Result::Rack>

=cut

__PACKAGE__->belongs_to(
  "rack",
  "ViroDB::Result::Rack",
  { rack_id => "rack_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2017-08-11 15:11:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:MQ+ml4SKP9TsUV8Mx48wdQ

sub next_empty_position {
    my ($self, $aliquot) = @_;
    my $next_position = $self->box_positions->search({
        aliquot_id => undef,
    }, { order_by => 'pos' })->first;
}

sub location {
    my $self = shift;
    return $self->rack->location . " / " . $self->name;
}

sub is_empty {
    my $self = shift;
    my $occupied_positions = $self->search_related('box_positions',
        { aliquot_id => { -not => undef } }
    )->count;
    return $occupied_positions == 0;
}

__PACKAGE__->meta->make_immutable;
1;
