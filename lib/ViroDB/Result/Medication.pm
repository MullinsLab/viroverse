use utf8;
package ViroDB::Result::Medication;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ViroDB::Result::Medication

=cut

use strict;
use warnings;

=head1 BASE CLASS: L<ViroDB::Result>

=cut

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'ViroDB::Result';

=head1 TABLE: C<viroserve.medication>

=cut

__PACKAGE__->table("viroserve.medication");

=head1 ACCESSORS

=head2 medication_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'viroserve.medication_medication_id_seq'

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 abbreviation

  data_type: 'text'
  is_nullable: 0

=head2 arv_class_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "medication_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "viroserve.medication_medication_id_seq",
  },
  "name",
  { data_type => "text", is_nullable => 0 },
  "abbreviation",
  { data_type => "text", is_nullable => 0 },
  "arv_class_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</medication_id>

=back

=cut

__PACKAGE__->set_primary_key("medication_id");

=head1 RELATIONS

=head2 arv_class

Type: belongs_to

Related object: L<ViroDB::Result::ArvClass>

=cut

__PACKAGE__->belongs_to(
  "arv_class",
  "ViroDB::Result::ArvClass",
  { arv_class_id => "arv_class_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 patient_medications

Type: has_many

Related object: L<ViroDB::Result::PatientMedication>

=cut

__PACKAGE__->has_many(
  "patient_medications",
  "ViroDB::Result::PatientMedication",
  { "foreign.medication_id" => "self.medication_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2017-08-11 15:11:37
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:FHetjVtbTM/T5Dn1KiJK2w

sub as_hash {
    my $self = shift;
    return {
        $self->get_columns,
        arv_class => $self->arv_class,
    };
}

__PACKAGE__->meta->make_immutable;
1;
