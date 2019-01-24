use utf8;
package ViroDB::Result::Rack;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ViroDB::Result::Rack

=cut

use strict;
use warnings;

=head1 BASE CLASS: L<ViroDB::Result>

=cut

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'ViroDB::Result';

=head1 TABLE: C<freezer.rack>

=cut

__PACKAGE__->table("freezer.rack");

=head1 ACCESSORS

=head2 rack_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'freezer.rack_rack_id_seq'

=head2 freezer_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 creating_scientist_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 owning_scientist_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 num_rows

  data_type: 'integer'
  default_value: 12
  is_nullable: 1

=head2 num_columns

  data_type: 'integer'
  default_value: 1
  is_nullable: 1

=head2 order_key

  data_type: 'integer'
  is_nullable: 1

=head2 name

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=cut

__PACKAGE__->add_columns(
  "rack_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "freezer.rack_rack_id_seq",
  },
  "freezer_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "creating_scientist_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "owning_scientist_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "num_rows",
  { data_type => "integer", default_value => 12, is_nullable => 1 },
  "num_columns",
  { data_type => "integer", default_value => 1, is_nullable => 1 },
  "order_key",
  { data_type => "integer", is_nullable => 1 },
  "name",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</rack_id>

=back

=cut

__PACKAGE__->set_primary_key("rack_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<freezer_rack_name_unique>

=over 4

=item * L</freezer_id>

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint("freezer_rack_name_unique", ["freezer_id", "name"]);

=head1 RELATIONS

=head2 boxes

Type: has_many

Related object: L<ViroDB::Result::Box>

=cut

__PACKAGE__->has_many(
  "boxes",
  "ViroDB::Result::Box",
  { "foreign.rack_id" => "self.rack_id" },
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

=head2 freezer

Type: belongs_to

Related object: L<ViroDB::Result::Freezer>

=cut

__PACKAGE__->belongs_to(
  "freezer",
  "ViroDB::Result::Freezer",
  { freezer_id => "freezer_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
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


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2017-08-14 10:39:29
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:FxOw7YgGBBunrRczXK94WQ


sub location {
    my $self = shift;
    $self->freezer->name . " / " . $self->name;
}

__PACKAGE__->meta->make_immutable;
1;
