use utf8;
package ViroDB::Result::NumericAssayResult;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ViroDB::Result::NumericAssayResult

=cut

use strict;
use warnings;

=head1 BASE CLASS: L<ViroDB::Result>

=cut

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'ViroDB::Result';

=head1 TABLE: C<viroserve.numeric_assay_result>

=cut

__PACKAGE__->table("viroserve.numeric_assay_result");

=head1 ACCESSORS

=head2 numeric_assay_result_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'viroserve.numeric_assay_result_numeric_assay_result_id_seq'

=head2 numeric_assay_protocol_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 sample_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 scientist_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 value

  data_type: 'numeric'
  is_nullable: 1

=head2 uri

  data_type: 'text'
  is_nullable: 1

=head2 note

  data_type: 'text'
  is_nullable: 1

=head2 date_completed

  data_type: 'date'
  is_nullable: 1

=head2 time_created

  data_type: 'timestamp with time zone'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=cut

__PACKAGE__->add_columns(
  "numeric_assay_result_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "viroserve.numeric_assay_result_numeric_assay_result_id_seq",
  },
  "numeric_assay_protocol_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "sample_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "scientist_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "value",
  { data_type => "numeric", is_nullable => 1 },
  "uri",
  { data_type => "text", is_nullable => 1 },
  "note",
  { data_type => "text", is_nullable => 1 },
  "date_completed",
  { data_type => "date", is_nullable => 1 },
  "time_created",
  {
    data_type     => "timestamp with time zone",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</numeric_assay_result_id>

=back

=cut

__PACKAGE__->set_primary_key("numeric_assay_result_id");

=head1 RELATIONS

=head2 protocol

Type: belongs_to

Related object: L<ViroDB::Result::NumericAssayProtocol>

=cut

__PACKAGE__->belongs_to(
  "protocol",
  "ViroDB::Result::NumericAssayProtocol",
  { numeric_assay_protocol_id => "numeric_assay_protocol_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
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


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2019-08-01 14:52:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:QJmRkcq3BZdoDaKtick7cA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
