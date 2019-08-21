
# links to PgDB virverse.viorserve.aliquot table and functions as the swicthboard for a sample's aliquots in the viroverse.freezer system.
package Viroverse::Model::aliquot;
use Moo;
BEGIN { extends 'Viroverse::CDBI' }
use Scalar::Util qw(looks_like_number);
use List::Util qw(first);
use Carp;
use ViroDB;

__PACKAGE__->table('viroserve.aliquot');
__PACKAGE__->sequence('viroserve.aliquot_aliquot_id_seq');
__PACKAGE__->columns(Primary => qw[aliquot_id]);
__PACKAGE__->columns(Other =>
   qw[
        vol
        unit_id
        creating_scientist_id
        sample_id
        possessing_scientist_id
        orphaned
        manifest_id
        num_thaws
        date_entered
        received_date
        vv_uid
        qc_d
        is_deleted
   ]
);

__PACKAGE__->has_a(creating_scientist_id => 'Viroverse::Model::scientist');
__PACKAGE__->has_a(possessing_scientist_id => 'Viroverse::Model::scientist');
__PACKAGE__->has_a(unit_id => 'Viroverse::Model::unit' );
__PACKAGE__->has_a(sample_id => 'Viroverse::Model::sample' );

sub status {
     return format_status($_[0]->isInFreezer(),
                           $_[0]->possessing_scientist_id,
                           $_[0]->qc_d,
                           $_[0]->orphaned);
}

sub format_status {
    my ($is_in_freezer, $possessing_scientist_id, $is_qc_d, $orphaned, $is_offsite) = @_;

    if ($is_in_freezer){
        return 'Reserved' if defined $possessing_scientist_id;
        return 'In ' . ($is_offsite ? 'off-site ' : q{}) . 'freezer (' . ($is_qc_d ? q{} : 'not ') . 'qc\'d)';
    }

     return 'Handed Out' if defined $possessing_scientist_id;
     return 'Lost'       if defined $orphaned;
     return 'Unknown';
}

sub format_location {
     my ($location, $possessing_scientist, $orphaned) = @_;

    if (defined $location) {
        $location .= " (Reserved for $possessing_scientist)" if defined $possessing_scientist;
        return $location;
    }
    return "(Given to $possessing_scientist)" if defined $possessing_scientist;
    return "Reported lost on $orphaned"     if defined $orphaned;
    return 'Location unknown';
}


=item validateField
    Validates field values from user input to make sure they coorespond to he database.
    does not bother to validate foreighn keys because the UI should not allow for manual user enrty of those and as such hey should come in as valid

    @param field string the name of the field to be validated
    @param val scalar the value to be validated
    @return boolian
=cut
sub validateField {
    my ($pkg, $field, $val) = @_;
    my %validation = (
        vol       => sub {return looks_like_number($_[0])},  #is numeric
        orphaned  => sub {return $_[0] =~ /^\d{4}-\d{2}-\d{2}$/ },
        num_thaws => sub {return $_[0] =~ /^\d{1,}$/ },
    );
    if(!defined $validation{$field}){ #if not validation then fine
        return 1;
    }
    return $validation{$field}($val);
}

=item location
 returns the whereabouts of the aliquot
=cut
sub location {
    my $self = shift;

    my $box_pos = $self->box_pos;
    my $location = $box_pos->location if $box_pos;
    my $possessing_scientist = $self->possessing_scientist_id()->name if defined $self->possessing_scientist_id;
    return format_location($location, $possessing_scientist, $self->orphaned);
}

sub box_pos {
# return box pos object containing current aliquot
    return ViroDB->instance->resultset("BoxPos")->search({ aliquot_id => $_[0]->aliquot_id })->single;
}

sub isInFreezer {
# return true if aliquote is in a freezer box position, else false
    return !!($_[0]->box_pos);
}

sub is_missing {
    my $self = shift;
    return !($self->box_pos || $self->possessing_scientist_id || $self->orphaned);
}

sub unit {
    return $_[0]->unit_id() ? $_[0]->unit_id->name() : undef;
}

sub to_string {
    my ($self) = @_;
    if (!$self->is_deleted) {
        my $sample = ($self->sample_id->to_string || q{});
        my $vol    = ($self->vol  || q{});
        my $unit   = ($self->unit || q{});
        return ($sample . q{ } || q{}) . ($vol . q{ } || q{}) . $unit;
    }
    else {
        return q{};
    }
}

# Routines to produce summary reports.  Might be nice to implement this as a view (either in the database
# or as a virtual view via Class::DBI::View).  Formatting functions might be moved to controller.
sub summary_detail {
    my ($arg_ref) = @_;

    # get selection criteria
    my ($selection_string, $sql_params) = build_selection_criteria($arg_ref);
    my $filter = build_filter($arg_ref->{filters});
    my $order_by = defined $arg_ref->{order_by} ? 'ORDER BY ' . $arg_ref->{order_by} : q{};

    # build query
    my $sql = "SELECT DISTINCT
                      a.aliquot_id,
                      a.orphaned,
                      a.vol,
                         a.possessing_scientist_id,
                         add.name AS additive,
                         b.box_id,
                         b.name   AS box,
                         b.order_key AS box_order_key,
                         bp.name  AS box_pos,
                         bp.pos   AS box_pos_int,
                         bp.box_pos_id NOTNULL AS is_in_freezer,
                      f.name AS freezer,
                         f.is_offsite,
                         r.name AS rack,
                         r.rack_id,
                         r.order_key AS rack_order_key,
                      s.name,
                      sc.name AS possessing_scientist,
                      t.name AS tissue,
                      s.tissue_type_id,
                      u.name AS unit,
                      p.sample_date AS visit_date,
                      p.patient_id,
                      s.sample_id as sample_id
               FROM  viroserve.aliquot a
                 JOIN viroserve.sample s
                   ON a.sample_id = s.sample_id
                 LEFT JOIN viroserve.derivation d USING (derivation_id)
                 LEFT JOIN viroserve.visit v USING (visit_id)
                 LEFT JOIN viroserve.sample_patient_date p ON (s.sample_id = p.sample_id)
                 LEFT JOIN viroserve.tissue_type t USING (tissue_type_id)
                 LEFT JOIN viroserve.unit u USING (unit_id)
                 LEFT JOIN viroserve.additive add USING (additive_id)
                 LEFT JOIN viroserve.scientist sc ON sc.scientist_id = a.possessing_scientist_id
                 LEFT JOIN freezer.box_pos bp
                      ON bp.aliquot_id = a.aliquot_id
                 LEFT JOIN freezer.box b USING (box_id)
                 LEFT JOIN freezer.rack r USING (rack_id)
                 LEFT JOIN freezer.freezer f USING (freezer_id)
               WHERE NOT a.is_deleted
                 $selection_string
                 $filter
               $order_by";

    # execute query and return results
    return __PACKAGE__->db_Main->selectall_arrayref($sql, { Slice => {} }, @{$sql_params});
}

sub summary_detail_by_box {
    my ($arg_ref) = @_;

    # get selection criteria
    my ($selection_string, $sql_params) = build_selection_criteria($arg_ref);
    my $filter = build_filter($arg_ref->{filters});
    my $order_by = defined $arg_ref->{order_by} ? 'ORDER BY ' . $arg_ref->{order_by} : q{};

    # build query
    my $sql = "SELECT DISTINCT
                      a.aliquot_id,
                      a.orphaned,
                      a.qc_d,
                      a.vol,
                         a.possessing_scientist_id,
                         add.name AS additive,
                         b.box_id,
                         b.name   AS box,
                         b.order_key AS box_order_key,
                         bp.name  AS box_pos,
                         bp.pos   AS box_pos_int,
                         bp.box_pos_id NOTNULL AS is_in_freezer,
                      f.name AS freezer,
                         r.name AS rack,
                         r.rack_id,
                         r.order_key AS rack_order_key,
                      s.name,
                      tt.name AS tissue,
                      u.name AS unit,
                      p.sample_date AS visit_date,
                      p.patient_id
               FROM freezer.box b
                    LEFT JOIN freezer.rack r USING (rack_id)
                    LEFT JOIN freezer.freezer f USING (freezer_id)
                    LEFT JOIN freezer.box_pos bp USING (box_id)
                    LEFT JOIN viroserve.aliquot a
                      ON a.aliquot_id = bp.aliquot_id
                     AND NOT a.is_deleted
                    LEFT JOIN viroserve.sample s
                      ON s.sample_id = a.sample_id
                    LEFT JOIN viroserve.visit v
                      ON v.visit_id = s.visit_id
                     AND NOT v.is_deleted
                    LEFT JOIN viroserve.derivation d USING (derivation_id)
                    LEFT JOIN viroserve.sample_patient_date p ON (s.sample_id = p.sample_id)
                    LEFT JOIN viroserve.tissue_type tt USING (tissue_type_id)
                 LEFT JOIN viroserve.unit u USING (unit_id)
                 LEFT JOIN viroserve.additive add USING (additive_id)
               WHERE TRUE
                 $selection_string
                 $filter
               $order_by";

    # execute query and return results
    return __PACKAGE__->db_Main->selectall_arrayref($sql, { Slice => {} }, @{$sql_params})
}

sub build_filter {
    my ($filter_ref) = @_;

    my $filter = q{};
    for my $item (map {lc $_} @{$filter_ref}) {
        if ($item eq 'empty') {
            $filter .= ' AND (a.vol IS NULL OR a.vol != 0)'
        }
        elsif ($item eq 'reserved') {
            $filter .= ' AND NOT (bp.aliquot_id IS NOT NULL AND a.possessing_scientist_id IS NOT NULL)'
        }
        elsif ($item eq 'given_out') {
            $filter .= ' AND NOT (bp.aliquot_id IS NULL AND a.possessing_scientist_id IS NOT NULL)'
        }
        elsif ($item eq 'offsite') {
            $filter .= ' AND (f.is_offsite IS NULL OR NOT f.is_offsite)'
        }
    }
    return $filter;
}

sub build_selection_criteria {
    my ($arg_ref) = @_;

    my $pull_by_patient     = defined $arg_ref->{patient_id};
    my $pull_by_scientist   = defined $arg_ref->{scientist};
    my $pull_by_box_pattern = defined $arg_ref->{box_pattern};
    my $pull_by_freezers    = (ref $arg_ref->{freezers}   eq 'ARRAY' && @{$arg_ref->{freezers}});
    my $pull_by_tissues     = (ref $arg_ref->{tissue_ids} eq 'ARRAY' && @{$arg_ref->{tissue_ids}});
    my $pull_by_dates       = (ref $arg_ref->{dates}      eq 'ARRAY' && @{$arg_ref->{dates}});

    my @sql_params;
    my $selection_string = q{};

    # by patient
    if ($pull_by_patient) {
        $selection_string .= "  AND p.patient_id = ?\n";
        push @sql_params, $arg_ref->{patient_id};
    }

    # by possessing scientist
    if ($pull_by_scientist) {
        $selection_string .= "  AND sc.name = ?\n";
        push @sql_params, $arg_ref->{scientist};
    }

    # by box name pattern
    if ($pull_by_box_pattern) {
        $selection_string .= "  AND b.name ILIKE ?\n";
        push @sql_params, $arg_ref->{box_pattern};
    }

    # by freezers
    if ($pull_by_freezers) {
        my @freezers = map {$_->id} @{$arg_ref->{freezers}};
        my $place_holders = join ',', map {'?'} @freezers;
        $selection_string .= "  AND (f.freezer_id IN (${place_holders}) OR f.freezer_id IS NULL)\n";
        push @sql_params, @freezers;
    }

    # by tissues
    if ($pull_by_tissues) {
        my @tissues;
        my $null = 0;
        my $tissue_string = '';
        for my $tissue (@{$arg_ref->{tissue_ids}}) {
            if (defined $tissue && looks_like_number($tissue) && $tissue >= 0) {
                push @tissues, $tissue;
            }
            else {
                $null = 1;
            }
        }
        if (@tissues) {
            my $place_holders = join ', ', map {'?'} @tissues;
            $tissue_string .= "  AND (tissue_type_id IN (${place_holders})";
            push @sql_params, @tissues;
        }
        if ($null) {
            $tissue_string .= ($tissue_string ? ' OR ' : '  AND (') . 'tissue_type_id IS NULL';
        }
        if ($tissue_string) {
            $selection_string .= $tissue_string . ")\n";
        }
    }

    # by visits
    if ($pull_by_dates) {
        my @dates = @{$arg_ref->{dates}};
        my $placeholders = join ', ', ('?') x @dates;
        $selection_string .= " AND p.sample_date IN ($placeholders)";
        push @sql_params, @dates;
    }

    return $selection_string, \@sql_params;
}

sub summary_by_box {
    my ($pkg, $arg_ref) = @_;

    $arg_ref->{order_by} = 'f.name, r.name, b.name, bp.pos, s.name';
    my $results_ref = summary_detail_by_box($arg_ref);

    # produce hierarchical data set box/aliquots
    my (@summary, $aliquot_ref, $session, $row_hold);
    if (@{$results_ref}) {
        $session = Viroverse::session->new(__PACKAGE__->db_Main);
        $row_hold = $results_ref->[0];
        $aliquot_ref = [];
    }

    # Loop through values
    for my $row (@{$results_ref}) {

        # Control break on rack and box
        unless ($row->{rack_id} == $row_hold->{rack_id} && $row->{box_id} eq $row_hold->{box_id}) {

            # Accumulate known tissue types (and unknown tissue types if no others exist)
            my $loc = $row_hold->{freezer} . ' / ' . $row_hold->{rack};
            push @summary, {location => $loc, rack => $row_hold->{rack_id}, box_id => $row_hold->{box_id}, box => $row_hold->{box}, aliquots => $aliquot_ref};

            # Re-initialize variables
            $row_hold = $row;
            $aliquot_ref = [];
        }

        # Accumulate aliquot data
        if (defined $row->{aliquot_id}) {
            my $names_ref = Viroverse::patient::get($session, $row->{patient_id})->get_prop('all_names');
            my $vol       = defined $row->{vol} && defined $row->{unit} ? "$row->{vol} $row->{unit}" : 'Unk';
            my $status    = format_status(@{$row}{('is_in_freezer', 'possessing_scientist_id', 'qc_d', 'orphaned')});
            my $visit     = $row->{visit_date} || 'Unk';
            push @{$aliquot_ref}, {id => $row->{aliquot_id}, name => $row->{name}, location => $row->{box_pos}, patient => $names_ref,
                                    visit_date => $visit, tissue => $row->{tissue}, vol => $vol, status => $status, additive => $row->{additive}};
        }
    }

    # catch final item if present and store result in stash
    if (@{$results_ref}) {
        my $loc = $row_hold->{freezer} . ' / ' . $row_hold->{rack};
        push @summary, {location => $loc, rack => $row_hold->{rack_id}, box_id => $row_hold->{box_id}, box => $row_hold->{box}, aliquots => $aliquot_ref};
    }
    return \@summary;
}

sub summary_by_patient {
    my ($arg_ref) = @_;

    $arg_ref->{order_by} = 'patient_id, visit_date, name, s.sample_id' . ($arg_ref->{order_by} ? ', ' . $arg_ref->{order_by} : '');
    my $results_ref = summary_detail($arg_ref);

    # produce hierarchical data set [product/aliquots]
    my ($row_hold, $total_vol);
    if (@{$results_ref}) {
        $row_hold = $results_ref->[0];
    }

    # loop through values
    my $missing_ct = 0;
    for my $row (@{$results_ref}) {

        # control break on patient, visit date and tissue type
        unless ($row->{patient_id} eq $row_hold->{patient_id} &&
                $row->{visit_date} eq $row_hold->{visit_date} &&
                $row->{sample_id} == $row_hold->{sample_id} &&
              ((!defined $row->{tissue} && !defined $row_hold->{tissue}) ||
                ( defined $row->{tissue} &&  defined $row_hold->{tissue} && $row->{tissue} eq $row_hold->{tissue}))) {

            # perform summary action
            $arg_ref->{summary_func}($row_hold);

            # re-initialize variables
            $row_hold = $row;
        }

        # perform detail action
        if (defined $row->{aliquot_id}) {
            $arg_ref->{detail_func}($row) if (defined $arg_ref->{detail_func});
        }

        # perform missing action for rows with a name but no aliquots
        elsif (!defined $row->{aliquot_id} && defined $row->{name}) {
            $arg_ref->{missing_func}($row, ++$missing_ct) if (defined $arg_ref->{missing_func});
        }
    }

    # catch final item if present and store result in stash
    if (@{$results_ref} and $row_hold) {
        $arg_ref->{summary_func}($row_hold);
    }
    return;
}

sub summary_selection {
    my ($pkg, $arg_ref) = @_;

    my $min_vials = $arg_ref->{min_vials} || 0;
    my $pull_by_tissues = (ref $arg_ref->{tissue_ids} eq 'ARRAY' && @{$arg_ref->{tissue_ids}});

    my (@visits, @tissues, %seen_visits, %seen_tissues, $return_ref);
    my $visit_ct   = 0;
    my $tissue_ct  = 0;
    my $aliquot_ct = 0;
    my @tissue_keys = qw(tissue_type_id tissue);

    $arg_ref->{summary_func} = sub {
        my ($row) = @_;
        if ($aliquot_ct >= $min_vials) {

            # accumulate visits
            if (!exists $seen_visits{$row->{visit_date}}) {
                $visits[$visit_ct++]->{visit_date} = $row->{visit_date};
                $seen_visits{$row->{visit_date}} = undef;
            }

            # accumulate tissues if required
            if (!$pull_by_tissues) {
                if (!defined $row->{tissue}) {
                    $row->{tissue} = 'Unk';
                    $row->{tissue_type_id} = '-1';
                }
                if (!exists $seen_tissues{$row->{tissue}}) {
                    @{$tissues[$tissue_ct++]}{@tissue_keys} = @{$row}{@tissue_keys};
                    $seen_tissues{$row->{tissue}} = undef;
                }
            }
        }
        $aliquot_ct = 0;
        return;
    };

    $arg_ref->{missing_func} = $arg_ref->{detail_func} = sub {
        $aliquot_ct++;
        return;
    };

    summary_by_patient($arg_ref);
    $return_ref->{visits}  = \@visits;
    $return_ref->{tissues} = \@tissues if !$pull_by_tissues;
    return $return_ref;
}

sub admin_summary_by_patient {
    my ($pkg, $arg_ref) = @_;

    my $min_vials = $arg_ref->{min_vials} || 0;
    my $session = Viroverse::session->new(__PACKAGE__->db_Main);

    $arg_ref->{order_by}   = 'f.name, r.order_key, b.order_key, bp.pos';

    my @summary;
    my $aliquots_ref = [];
    $arg_ref->{summary_func} = sub {
        my ($row) = @_;
        if (@{$aliquots_ref} >= $min_vials) {
            my $names_ref = Viroverse::patient::get($session, $row->{patient_id})->get_prop('all_names');
            my $tissue    = defined $row->{tissue} ? $row->{tissue} : 'Unk';
            push @summary, {patient => $names_ref, visit_date => $row->{visit_date}, tissue => $tissue, aliquots => $aliquots_ref};
            $aliquots_ref = [];
        }
        return;
    };

    $arg_ref->{detail_func} = sub {
        my ($row) = @_;
        my $loc = $row->{freezer} . ' / ' . $row->{rack} . ' / ' . $row->{box} . ' / ' . $row->{box_pos} if defined $row->{freezer};
        my $location = format_location($loc, $row->{possessing_scientist}, $row->{orphaned});
        push @{$aliquots_ref}, {id => $row->{aliquot_id}, count => 1, vol => $row->{vol}, unit => $row->{unit}, location => $location, rack_id => $row->{rack_id}, box_id => $row->{box_id}, name => $row->{name}, additive => $row->{additive}};
        return;
    };

    $arg_ref->{missing_func} = sub {
        my ($row, $missing_ct) = @_;
        my $loc = $row->{freezer} . ' / ' . $row->{rack} . ' / ' . $row->{box} . ' / ' . $row->{box_pos} if defined $row->{freezer};
        my $location = format_location($loc, $row->{possessing_scientist}, $row->{orphaned});
        push @{$aliquots_ref}, {id => -$missing_ct, count => undef,  vol => $row->{vol}, unit => $row->{unit}, location => $location, rack_id => $row->{rack_id}, box_id => $row->{box_id}, name => $row->{name}, additive => $row->{additive}};
        return;
    };
    summary_by_patient($arg_ref);
    return \@summary
}

sub TO_JSON {
    my ($self, $show_loc) = @_;
    my $possessing_sci = q{};
    my $possessing_sci_id = q{};
    if($self->possessing_scientist_id()){
        $possessing_sci = $self->possessing_scientist_id->name();
        $possessing_sci_id = $self->possessing_scientist_id->scientist_id();
    }
    return {
        aliquot_id => $self->aliquot_id(),
        vol => $self->vol(),
        units => ($self->unit_id ? $self->unit_id->name : undef),
        location => $show_loc?$self->location():q{},
        name => $self->to_string(),
        orphaned => defined($self->orphaned())?$self->orphaned():q{},
        num_thaws => $self->num_thaws(),
        possessing_scientist => $possessing_sci,
        possessing_scientist_id => $possessing_sci_id,
        isInFreezer => $self->isInFreezer(),
    };
}

1;

