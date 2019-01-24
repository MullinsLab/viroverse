use utf8;
package ViroDB::Result::ArvClass;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ViroDB::Result::ArvClass

=cut

use strict;
use warnings;

=head1 BASE CLASS: L<ViroDB::Result>

=cut

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'ViroDB::Result';

=head1 TABLE: C<viroserve.arv_class>

=cut

__PACKAGE__->table("viroserve.arv_class");

=head1 ACCESSORS

=head2 arv_class_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'viroserve.arv_class_arv_class_id_seq'

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 abbreviation

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "arv_class_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "viroserve.arv_class_arv_class_id_seq",
  },
  "name",
  { data_type => "text", is_nullable => 0 },
  "abbreviation",
  { data_type => "text", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</arv_class_id>

=back

=cut

__PACKAGE__->set_primary_key("arv_class_id");

=head1 RELATIONS

=head2 medications

Type: has_many

Related object: L<ViroDB::Result::Medication>

=cut

__PACKAGE__->has_many(
  "medications",
  "ViroDB::Result::Medication",
  { "foreign.arv_class_id" => "self.arv_class_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2017-08-11 15:11:37
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:M4IqscTAbSLHK0+rHjo2JA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
