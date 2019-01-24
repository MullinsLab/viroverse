use strict;
use warnings;
use utf8;
use 5.018;

package Viroverse::Import::Patients;
use Moo;
use Viroverse::Logger qw< :log :dlog >;
use Types::Standard -types;
use Viroverse::Types -types;
use Types::Common::String -types;
use ViroDB;
use namespace::clean;

with 'Viroverse::Import',
     'Viroverse::Import::CanPreparePatient';

=head1 DESCRIPTION

=encoding UTF-8

This importer idempotently loads subjects for a single cohort and, optionally,
their other aliases and basic demographic information.

Each data file row should contain details about a single subject.

The subject is looked up by their primary ID within the cohort.  If no such
subject exists, a new subject record is created and given a primary ID
for the cohort.

Any additional publication IDs or alternate IDs (aliases) are created if they
do not already exist. Note that existing aliases will not be removed and empty
values in a data column are ignored.

Any demographic fields selected for import will be updated with values from the
data.  Empty values for demographic fields will remove the current database
value.

=cut

has '+key_map' => (
    isa => Dict[
        external_patient_id => NonEmptySimpleStr,
        publication_id      => Optional[SimpleStr],
        alternate_id        => Optional[SimpleStr],
        gender              => Optional[SimpleStr],
        birth               => Optional[SimpleStr],
    ],
);

sub suggested_column_for_key_pattern {
    my ($package, $key) = @_;
    return {
        external_patient_id => qr/patient|subject|participant/i,
        publication_id      => qr/pub/i,
        alternate_id        => qr/alt/i,
    }->{$key};
}

my $alias_types = {
    # field        => patient_alias.type
    publication_id => "publication",
    alternate_id   => "alias",
};

sub process_row {
    my ($self, $row) = @_;

    my $external_patient_id = delete $row->{external_patient_id};
    my $patient             = $self->find_or_create_patient( $external_patient_id );

    # Create any other aliases, if they've been mapped
    for my $alias_key (grep { exists $row->{$_} } sort keys %$alias_types) {
        my $id = delete $row->{$alias_key};

        # Ignore empty values in mapped alias fields
        next unless defined $id and length $id;

        my $alias = $patient->patient_aliases->find_or_new({
            patient_id          => $patient->id,
            cohort_id           => $self->cohort->id,
            external_patient_id => $id,
            type                => $alias_types->{$alias_key},
        });

        if ($alias->in_storage) {
            log_debug {[
                "Patient %s %s %s found: %s",
                $self->cohort->name,
                $external_patient_id,
                $alias_key =~ s/_/ /gr,
                $alias->external_patient_id
            ]};
            $self->track("Alias found");
        }
        else {
            $alias->insert;

            log_info {[
                "Patient %s %s %s created: %s",
                $self->cohort->name,
                $external_patient_id,
                $alias_key =~ s/_/ /gr,
                $alias->external_patient_id
            ]};
            $self->track("Alias created");
        }
    }

    # If there were no demographic fields mapped, then we're done!
    if (%$row) {
        my $old = { $patient->get_columns };

        # Only update these fields if they were mapped to data file columns.
        # Empty strings (or other falsey values) are forced to undef which maps
        # to NULL.
        $patient->gender( $row->{gender} || undef )
            if exists $row->{gender};

        $patient->birth( $row->{birth} || undef )
            if exists $row->{birth};

        # Save any changes and reload from database to normalize values
        $patient->update->discard_changes;

        # Figure out what we changed, if anything.
        my $new     = { $patient->get_columns };
        my @updated =
            grep { ($old->{$_} // "") ne ($new->{$_} // "") }
                 sort keys %$row;

        if (@updated) {
            $self->track("Patient updated");
            log_info {[ "Patient %s %s %s updated", $self->cohort->name, $external_patient_id, _wordlist(@updated) ]};
        } else {
            $self->track("Patient unchanged");
            log_debug {[ "Patient %s %s %s unchanged", $self->cohort->name, $external_patient_id, _wordlist(keys %$row) ]};
        }
    }
}

sub _wordlist {
    my @words = @_
        or return;

    return join " and ", @words
        if @words == 2;

    push @words, join ", and ", splice @words, -2
        if @words > 2;
    return join ", ", @words;
}

1;
