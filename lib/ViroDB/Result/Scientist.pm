use utf8;
package ViroDB::Result::Scientist;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ViroDB::Result::Scientist

=cut

use strict;
use warnings;

=head1 BASE CLASS: L<ViroDB::Result>

=cut

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'ViroDB::Result';

=head1 TABLE: C<viroserve.scientist>

=cut

__PACKAGE__->table("viroserve.scientist");

=head1 ACCESSORS

=head2 scientist_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'viroserve.scientist_scientist_id_seq'

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 start_date

  data_type: 'date'
  is_nullable: 1

=head2 end_date

  data_type: 'date'
  is_nullable: 1

=head2 phone

  data_type: 'char'
  is_nullable: 1
  size: 10

=head2 username

  data_type: 'varchar'
  is_nullable: 1
  size: 120

=head2 email

  data_type: 'varchar'
  is_nullable: 1
  size: 120

=head2 role

  data_type: 'viroserve.scientist_role'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "scientist_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "viroserve.scientist_scientist_id_seq",
  },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "start_date",
  { data_type => "date", is_nullable => 1 },
  "end_date",
  { data_type => "date", is_nullable => 1 },
  "phone",
  { data_type => "char", is_nullable => 1, size => 10 },
  "username",
  { data_type => "varchar", is_nullable => 1, size => 120 },
  "email",
  { data_type => "varchar", is_nullable => 1, size => 120 },
  "role",
  { data_type => "viroserve.scientist_role", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</scientist_id>

=back

=cut

__PACKAGE__->set_primary_key("scientist_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<scientist_username_key>

=over 4

=item * L</username>

=back

=cut

__PACKAGE__->add_unique_constraint("scientist_username_key", ["username"]);

=head1 RELATIONS

=head2 aliquots_created

Type: has_many

Related object: L<ViroDB::Result::Aliquot>

=cut

__PACKAGE__->has_many(
  "aliquots_created",
  "ViroDB::Result::Aliquot",
  { "foreign.creating_scientist_id" => "self.scientist_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 aliquots_held

Type: has_many

Related object: L<ViroDB::Result::Aliquot>

=cut

__PACKAGE__->has_many(
  "aliquots_held",
  "ViroDB::Result::Aliquot",
  { "foreign.possessing_scientist_id" => "self.scientist_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 bisulfite_converted_dnas

Type: has_many

Related object: L<ViroDB::Result::BisulfiteConvertedDNA>

=cut

__PACKAGE__->has_many(
  "bisulfite_converted_dnas",
  "ViroDB::Result::BisulfiteConvertedDNA",
  { "foreign.scientist_id" => "self.scientist_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 boxes_created

Type: has_many

Related object: L<ViroDB::Result::Box>

=cut

__PACKAGE__->has_many(
  "boxes_created",
  "ViroDB::Result::Box",
  { "foreign.creating_scientist_id" => "self.scientist_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 boxes_owned

Type: has_many

Related object: L<ViroDB::Result::Box>

=cut

__PACKAGE__->has_many(
  "boxes_owned",
  "ViroDB::Result::Box",
  { "foreign.owning_scientist_id" => "self.scientist_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 categorical_lab_results

Type: has_many

Related object: L<ViroDB::Result::CategoricalLabResult>

=cut

__PACKAGE__->has_many(
  "categorical_lab_results",
  "ViroDB::Result::CategoricalLabResult",
  { "foreign.scientist_id" => "self.scientist_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 chromats

Type: has_many

Related object: L<ViroDB::Result::Chromat>

=cut

__PACKAGE__->has_many(
  "chromats",
  "ViroDB::Result::Chromat",
  { "foreign.scientist_id" => "self.scientist_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 copy_numbers

Type: has_many

Related object: L<ViroDB::Result::CopyNumber>

=cut

__PACKAGE__->has_many(
  "copy_numbers",
  "ViroDB::Result::CopyNumber",
  { "foreign.scientist_id" => "self.scientist_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 derivations

Type: has_many

Related object: L<ViroDB::Result::Derivation>

=cut

__PACKAGE__->has_many(
  "derivations",
  "ViroDB::Result::Derivation",
  { "foreign.scientist_id" => "self.scientist_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 extractions

Type: has_many

Related object: L<ViroDB::Result::Extraction>

=cut

__PACKAGE__->has_many(
  "extractions",
  "ViroDB::Result::Extraction",
  { "foreign.scientist_id" => "self.scientist_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 freezers_created

Type: has_many

Related object: L<ViroDB::Result::Freezer>

=cut

__PACKAGE__->has_many(
  "freezers_created",
  "ViroDB::Result::Freezer",
  { "foreign.creating_scientist_id" => "self.scientist_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 freezers_owned

Type: has_many

Related object: L<ViroDB::Result::Freezer>

=cut

__PACKAGE__->has_many(
  "freezers_owned",
  "ViroDB::Result::Freezer",
  { "foreign.owning_scientist_id" => "self.scientist_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 gels

Type: has_many

Related object: L<ViroDB::Result::Gel>

=cut

__PACKAGE__->has_many(
  "gels",
  "ViroDB::Result::Gel",
  { "foreign.scientist_id" => "self.scientist_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 group_memberships

Type: has_many

Related object: L<ViroDB::Result::ScientistGroupMember>

=cut

__PACKAGE__->has_many(
  "group_memberships",
  "ViroDB::Result::ScientistGroupMember",
  { "foreign.scientist_id" => "self.scientist_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 group_memberships_created

Type: has_many

Related object: L<ViroDB::Result::ScientistGroupMember>

=cut

__PACKAGE__->has_many(
  "group_memberships_created",
  "ViroDB::Result::ScientistGroupMember",
  { "foreign.creating_scientist_id" => "self.scientist_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 groups_created

Type: has_many

Related object: L<ViroDB::Result::ScientistGroup>

=cut

__PACKAGE__->has_many(
  "groups_created",
  "ViroDB::Result::ScientistGroup",
  { "foreign.creating_scientist_id" => "self.scientist_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 import_jobs

Type: has_many

Related object: L<ViroDB::Result::ImportJob>

=cut

__PACKAGE__->has_many(
  "import_jobs",
  "ViroDB::Result::ImportJob",
  { "foreign.scientist_id" => "self.scientist_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 na_sequences

Type: has_many

Related object: L<ViroDB::Result::NucleicAcidSequence>

=cut

__PACKAGE__->has_many(
  "na_sequences",
  "ViroDB::Result::NucleicAcidSequence",
  { "foreign.scientist_id" => "self.scientist_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 numeric_lab_results

Type: has_many

Related object: L<ViroDB::Result::NumericLabResult>

=cut

__PACKAGE__->has_many(
  "numeric_lab_results",
  "ViroDB::Result::NumericLabResult",
  { "foreign.scientist_id" => "self.scientist_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 patient_groups_created

Type: has_many

Related object: L<ViroDB::Result::PatientGroup>

=cut

__PACKAGE__->has_many(
  "patient_groups_created",
  "ViroDB::Result::PatientGroup",
  { "foreign.scientist_id" => "self.scientist_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 pcr_products

Type: has_many

Related object: L<ViroDB::Result::PolymeraseChainReactionProduct>

=cut

__PACKAGE__->has_many(
  "pcr_products",
  "ViroDB::Result::PolymeraseChainReactionProduct",
  { "foreign.scientist_id" => "self.scientist_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 pcr_templates

Type: has_many

Related object: L<ViroDB::Result::PolymeraseChainReactionTemplate>

=cut

__PACKAGE__->has_many(
  "pcr_templates",
  "ViroDB::Result::PolymeraseChainReactionTemplate",
  { "foreign.scientist_id" => "self.scientist_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 projects_created

Type: has_many

Related object: L<ViroDB::Result::Project>

=cut

__PACKAGE__->has_many(
  "projects_created",
  "ViroDB::Result::Project",
  { "foreign.orig_scientist_id" => "self.scientist_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 racks_created

Type: has_many

Related object: L<ViroDB::Result::Rack>

=cut

__PACKAGE__->has_many(
  "racks_created",
  "ViroDB::Result::Rack",
  { "foreign.creating_scientist_id" => "self.scientist_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 racks_owned

Type: has_many

Related object: L<ViroDB::Result::Rack>

=cut

__PACKAGE__->has_many(
  "racks_owned",
  "ViroDB::Result::Rack",
  { "foreign.owning_scientist_id" => "self.scientist_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 rt_products

Type: has_many

Related object: L<ViroDB::Result::ReverseTranscriptionProduct>

=cut

__PACKAGE__->has_many(
  "rt_products",
  "ViroDB::Result::ReverseTranscriptionProduct",
  { "foreign.scientist_id" => "self.scientist_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 sample_assignments

Type: has_many

Related object: L<ViroDB::Result::ProjectSample>

=cut

__PACKAGE__->has_many(
  "sample_assignments",
  "ViroDB::Result::ProjectSample",
  { "foreign.desig_scientist_id" => "self.scientist_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 sample_notes

Type: has_many

Related object: L<ViroDB::Result::SampleNote>

=cut

__PACKAGE__->has_many(
  "sample_notes",
  "ViroDB::Result::SampleNote",
  { "foreign.scientist_id" => "self.scientist_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2019-04-30 14:38:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:J61JWqc6CWNtuCFlLaCW7w

use JSON::MaybeXS;
use Viroverse::config;
use namespace::autoclean;

sub can_browse    { $_[0]->role ne "retired" }
sub can_edit      { $_[0]->can_browse && $_[0]->role ne "browser" }
sub is_supervisor { $_[0]->role eq "supervisor" }
sub is_admin      { $_[0]->role eq "admin" }
sub is_retired    { $_[0]->role eq "retired" }

sub censor_dates {
    $Viroverse::config::features->{censor_dates} && $_[0]->role eq "browser"
}

sub can_manage_freezers { $_[0]->is_admin || $_[0]->is_supervisor }

sub as_hash {
    my $self = shift;
    my $hash = $self->next::method(@_);
    return {
        %$hash,

        # Add the convenience booleans for the benefit of our JS
        map { $_ => $self->$_ ? JSON->true : JSON->false }
            qw[
                is_supervisor
                is_admin
                is_retired
                can_manage_freezers
                censor_dates
                can_browse
                can_edit
             ]
    };
}

__PACKAGE__->meta->make_immutable;
1;
