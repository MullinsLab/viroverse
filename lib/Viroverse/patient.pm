package Viroverse::patient;
use Viroverse::db;
use Viroverse::session;
use Data::Dump;
use Carp qw[croak carp];
use strict;
use DateTime::Format::Strptime qw[strptime];
use DateTime::Format::Duration;

## Viroverse patient handling, bmaust July, 2005

my $patient_alias_sql = '
SELECT
    patient_id,
    external_patient_id,
    cohort.name as cohort,
    viroserve.patient_name(patient_id) as patient_name,
    gender
    FROM viroserve.patient
    JOIN viroserve.patient_alias using (patient_id)
    JOIN viroserve.cohort
        USING (cohort_id)
';


#deferred props are not loaded until asked for, then saved.
#value should be a subroutine accepting $self and returning a scalar

sub _get_prop_infection_window {
    my $column = shift
        or die "column required for ", __PACKAGE__, "::infection_window";
    grep { $column eq $_ } qw(infection seroconv symptom)
        or die "invalid column name";
    return sub {
        my $self = shift;
        my $row  = $self->{session}->{'dbr'}->selectrow_arrayref(qq[
            SELECT ${column}_earliest,
                   ${column}_latest,
                   ${column}_earliest + ((${column}_latest - ${column}_earliest) / 2)
              FROM viroserve.infection
             WHERE patient_id = ?
        ], undef, $self->give_id);
        return $row;
    }
}

#TODO: these should (ALL) be using caching the prepared statement
my %deferred_props = (
    vv_uid => sub {
        my $self = shift;
        return $self->{session}->{'dbr'}->selectcol_arrayref(q[
            SELECT vv_uid FROM viroserve.patient WHERE patient_id = ?
        ],undef,$self->give_id)->[0];
    },
    all_names => sub {
        my $self = shift;
        return $self->{all_names} if defined $self->{all_names};

        $self->{all_names} = $self->{session}->{'dbr'}->selectcol_arrayref(q[
            SELECT viroserve.patient_name_by_cohort(patient_id,cohort_id)
              FROM viroserve.patient_cohort
             WHERE patient_id = ?
            ORDER BY cohort_id;
        ],undef,$self->give_id);
    },
    hla => sub {
        my $self = shift;
        return $self->{session}->{'dbr'}->selectcol_arrayref(q[
            SELECT viroserve.hla_designation(hla_genotype_id) from viroserve.patient_hla_genotype where patient_id = ?
        ],undef,$self->give_id);
    },
    meds => sub {
        my $self = shift;
        my $db = $self->{session}->{'dbr'};

        my $meds_sh = $db->prepare_cached(q[
            SELECT medication_id,medication.abbreviation as medication_name,start_date as start_earliest,end_date as stop_latest
              FROM viroserve.patient_medication
              JOIN viroserve.medication USING (medication_id)
            where patient_id=?
            order by patient_id,start_earliest,stop_latest
        ]);
        $meds_sh->execute($self->get_prop('patient_id'));

        return $meds_sh->fetchall_arrayref({});
    },
    estimated_infection_date => sub {
        my $self = shift;
        my $row  = $self->{session}->{'dbr'}->selectrow_arrayref(q[
            SELECT infection.estimated_date FROM viroserve.infection WHERE patient_id = ?
        ], undef, $self->give_id);
        return $row->[0];
    },
    infection_date      => _get_prop_infection_window('infection'),
    seroconversion_date => _get_prop_infection_window('seroconv'),
    symptom_date        => _get_prop_infection_window('symptom'),
);

# returns a patient with supplied identifier
# which may be by internal patient identifier (patient_id)
# or cohort-assigned identifier (external_patient_id)
# depending on signature
sub get {
    my $session = shift @_;
    my @search = @_;
    my $patient;
    if ($#search == 0) {
        my $patient_id = $search[0];
        my $sql = $patient_alias_sql.' WHERE patient_id=? AND type=\'primary\'';
        $patient = Viroverse::db::selectrow_hr($session,$sql,undef,($patient_id));
    }
    # TODO: this needs to handle multiple cohort-ids
    elsif ($#search == 1) {
        my ($external_patient_id,$cohort) = @search;
        if (ref $cohort eq 'HASH') {
            my $sql = $patient_alias_sql.' WHERE external_patient_id=? AND '.(join ' AND ', map { "$_ = ?" } keys %{$cohort});
            $patient = Viroverse::db::selectrow_hr($session,$sql,undef,($external_patient_id,values %{$cohort}));
        } else {
            carp "deprecated use of patient::get(), should pass hash ref instead of cohort name";
            my $sql = $patient_alias_sql.' WHERE external_patient_id=? AND cohort.name=?';
            $patient = Viroverse::db::selectrow_hr($session,$sql,undef,($external_patient_id,$cohort));
        }
    } else {
        die "$#search is wrong index";
    }

    return if (keys %$patient) < 1;

    my $self = bless Viroverse::db::mk_obj($session,$patient);

    return $self;
}

=item groups()
    returns an array of groups to which this patient belongs
=cut

sub groups {
    my $self = shift @_;

    return _get_groups($self->{'session'}, $self->{'patient_id'});

}

=item cohort_patients
returns hashref keyed by external_patient_ids with the patient_ids for a cohort
optional additional parameter matches on beginning of string
=cut

sub cohort_patients {
    my ($session,$cohort_id, $ext_pat_id_start) = (@_);
    my @binds;

    my $sql = 'SELECT external_patient_id,patient_id from viroserve.patient_alias where cohort_id = ?';
    push @binds, $cohort_id;

    if (defined $ext_pat_id_start) {
        $sql.= ' AND external_patient_id like ?';
        push @binds, $ext_pat_id_start.'%';
    }

    return $session->{'dbr'}->selectall_hashref($sql,'external_patient_id',undef,@binds);
}

=item list

for enum, returns ordered array of matching patients in a cohort

=cut

sub list {
    my ($session,$cohort_id, $ext_pat_id_start) = (@_);
    my @binds;

    if (length $cohort_id < 1) {
        return [];
    }

    my $sql = 'SELECT external_patient_id,patient_id from viroserve.patient_alias where cohort_id = ?';
    push @binds, $cohort_id;

    if (defined $ext_pat_id_start) {
        $sql.= ' AND external_patient_id ilike ?';
        push @binds, $ext_pat_id_start.'%';
    }

    $sql .= 'ORDER BY external_patient_id';

    my $sh = $session->{'dbr'}->prepare($sql);
    $sh->execute(@binds);

    my @return;
    while (my $row = $sh->fetchrow_hashref) {
        push @return, $row;
    }

    return @return;

}

#private method to retrieve groups for a patient_id
sub _get_groups {
    my ($session,$patient_id) = @_;

    die "need a session and a patient_id, got @_" unless ($session && $patient_id);
    my $sql = q[
        SELECT patient_group.name
          FROM viroserve.patient_group
          JOIN viroserve.patient_patient_group using (patient_group_id)
         WHERE patient_id = ?
        ];

    return @{$session->{'dbr'}->selectcol_arrayref($sql, undef,$patient_id)};

}

sub get_prop {
    my ($self,$prop) = (shift, shift);
    return $self->{$prop} if exists $self->{$prop};
    if (exists $deferred_props{$prop}) {
        $self->{$prop} = &{$deferred_props{$prop}}($self);
        return $self->{$prop};
    }
    carp "$prop not set!";
    return undef;
}

sub give_id {
    my $self = shift;
    return $self->get_prop('patient_id');
}

sub to_string {
    return $_[0]->get_prop('patient_name');
}

sub time_to_first_art {
    my $self = shift;
    my $start_art = $self->get_prop('meds')->[0]->{start_earliest};
    my $date_infected = $self->get_prop('estimated_infection_date');
    if ($start_art && $date_infected) {
        my $d = DateTime::Format::Duration->new(
            pattern => '%j');
        my $time = strptime('%F', $start_art)->subtract_datetime(strptime('%F', $date_infected));
        my $days = $d->format_duration($time);
        return $days;
    }
}

1;
