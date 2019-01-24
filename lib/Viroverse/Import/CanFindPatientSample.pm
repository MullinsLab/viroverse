use strict;
use warnings;
use utf8;
use 5.018;

package Viroverse::Import::CanFindPatientSample;
use Moo::Role;
use Type::Params qw< compile Invocant >;
use Types::Common::String -types;
use Types::Standard -types;
use Viroverse::Types -types;
use Viroverse::Logger qw< :log :dlog >;
use namespace::clean;

=head1 METHODS

=head2 find_patient_sample

Given a L<cohort record|ViroDB::Result::Cohort>, external patient id, and a
hashref of fields, retrieve a unique sample record matching the query fields.

Returns a tuple of a L<ViroDB::Result::Patient> and a
L<ViroDB::Result::Sample>.  If either can't be found, throws an exception.

Supported fields:

=over

=item C<name> (sample name)

=item C<tissue_type> (required)

=item C<date> (required)

=item C<additive>

=back

=cut

sub find_patient_sample {
    state $params = compile(
        Invocant,
        ViroDBRecord["Cohort"],
        NonEmptySimpleStr,
        Dict[
            name        => Optional[Maybe[SimpleStr]],
            tissue_type => NonEmptySimpleStr,
            date        => NonEmptySimpleStr,
            additive    => Optional[Maybe[SimpleStr]],
        ]
    );

    my ($self, $cohort, $external_patient_id, $criteria) = $params->(@_);

    my $patient = $cohort->find_patient_by_alias( $external_patient_id )
        or log_fatal {[ "%s patient %s not found", $cohort->name, $external_patient_id ]};

    my $sample = $patient->samples->find_naturally($criteria)
        or Dlog_fatal {[ "%s patient %s sample not found: %s", $cohort->name, $external_patient_id, $_ ]} $criteria;

    log_debug {[ "Found sample ID: %s", $sample->id ]};

    return ($patient, $sample);
}

1;
