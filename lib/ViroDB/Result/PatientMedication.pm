use utf8;
package ViroDB::Result::PatientMedication;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ViroDB::Result::PatientMedication

=cut

use strict;
use warnings;

=head1 BASE CLASS: L<ViroDB::Result>

=cut

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'ViroDB::Result';

=head1 TABLE: C<viroserve.patient_medication>

=cut

__PACKAGE__->table("viroserve.patient_medication");

=head1 ACCESSORS

=head2 patient_medication_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'viroserve.patient_medication_patient_medication_id_seq'

=head2 start_date

  data_type: 'date'
  is_nullable: 1

when null: start date unknown, i.e. patient was on this medication prior to first contact

=head2 end_date

  data_type: 'date'
  is_nullable: 1

when null: this medication was ongoing at last point of contact

=head2 patient_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 medication_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 not_on_art

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "patient_medication_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "viroserve.patient_medication_patient_medication_id_seq",
  },
  "start_date",
  { data_type => "date", is_nullable => 1 },
  "end_date",
  { data_type => "date", is_nullable => 1 },
  "patient_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "medication_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "not_on_art",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</patient_medication_id>

=back

=cut

__PACKAGE__->set_primary_key("patient_medication_id");

=head1 RELATIONS

=head2 medication

Type: belongs_to

Related object: L<ViroDB::Result::Medication>

=cut

__PACKAGE__->belongs_to(
  "medication",
  "ViroDB::Result::Medication",
  { medication_id => "medication_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 patient

Type: belongs_to

Related object: L<ViroDB::Result::Patient>

=cut

__PACKAGE__->belongs_to(
  "patient",
  "ViroDB::Result::Patient",
  { patient_id => "patient_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2017-08-11 15:11:37
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:yP8kmz6hhD6Ylm3Kk0r+xw

sub _unknown_medication {
    my $self = shift;
    return $self->result_source->related_source('medication')->resultset->new_unknown;
}

sub medication_or_unknown_art {
    my $self = shift;
    return $self->medication ?          $self->medication :
           $self->not_on_art ?                      undef :
                               $self->_unknown_medication ;
}

sub as_hash {
    my $self = shift;
    return {
        $self->get_columns,
        medication => $self->medication_or_unknown_art,
    };
}

__PACKAGE__->meta->make_immutable;
1;
