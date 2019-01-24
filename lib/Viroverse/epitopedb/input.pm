package Viroverse::epitopedb::input;

use strict;
use warnings;
use ViroDB;

sub getFileLines {
    my ($buffer_ref) = @_;
    my $line = "";
    foreach my $row (@$buffer_ref) {
        if ($row =~ /\r\n/) {
             $row =~ s/\r//g;
         }elsif ($row =~ /\r/) {
             $row =~ s/\r/\n/g;
         }
         $line .= $row;
    }
    my @lines = split /\n/, $line;
    return \@lines;
}

sub change2unix {
    my ($target, $unix) = @_;
    open IN, $target or die "Couldn't open $target: $!\n";
    open UNIX, ">$unix" or die "Couldn't open $unix: $!\n";
    my @buffer = <IN>;
    foreach my $line (@buffer) {
        if ($line =~ /\r\n/) {
             $line =~ s/\r//g;
         }elsif ($line =~ /\r/) {
             $line =~ s/\r/\n/g;
         }
         print UNIX $line;
    }
    close IN;
    close UNIX;
}

sub cleanFields {
    my $fieldsRef = shift;
    my @cleans;
    foreach my $field (@$fieldsRef) {
        if (defined $field) {
            $field =~ s/^\s+// if ($field =~ /^\s+/);
            $field =~ s/\s+$// if ($field =~ /\s+$/);
        }

        push @cleans, $field;
    }
    return @cleans;
}

sub list_years {
    my @years;
    for (my $i = 1995; $i <= 1900 + (gmtime)[5]; $i++) {
        push @years, $i;
    }
    return \@years;
}

sub list_months {
    my @months;
    for (my $i = 1; $i <= 12; $i++) {
        my $month;
        if ($i < 10) {
            $month = "0".$i;
        }else {
            $month = $i;
        }
        push @months, $month;
    }
    return \@months;
}

sub list_days {
    my @days;
    for (my $i = 1; $i <= 31; $i++) {
        my $day;
        if ($i < 10) {
            $day = "0".$i;
        }else {
            $day = $i;
        }
        push @days, $day;
    }
    return \@days;
}

sub list_concs {
    my $schema = shift;

    my @concs = $schema->resultset('titration_conc')->all;
    return \@concs;
}

sub list_blcls {
    my $schema = shift;

    my @blcls = $schema->resultset('blcl')->search(
        undef,
        {
            order_by => 'name'
        }
    );
    return \@blcls;
}

sub list_hlas {
    my $schema = shift;

    my @hlas = $schema->resultset('hla')->search(
        undef,
        {
            order_by => 'type'
        }
    );
    return \@hlas;
}

sub get_origins {
    my $schema = shift;
    my @origins = $schema->resultset('origin')->search(
        undef,
        {
            order_by => 'name'
        }
    );
    return \@origins;
}

sub get_origin_id {
    my ($schema, $origin) = @_;
    my $origin_obj = $schema->resultset('origin')->fine({name => {'ilike' => $origin}});
    if (!$origin_obj) {
        $origin_obj = $schema->resultset('origin')->create({name => $origin});
    }
    return $origin_obj->origin_id;
}

sub get_regions {
    my $schema = shift;
    my @regions = $schema->resultset('gene')->all;
    return \@regions;
}

sub get_gene_id {
    my ($schema, $gene) = @_;
    my $gene_id;
    my $gene_obj = $schema->resultset('gene')->find ({gene_name => {'ilike' => $gene}});
    if ($gene_obj) {
        $gene_id = $gene_obj->gene_id;
    }
    return $gene_id;
}

sub get_exp_id {
    my ($schema, $exp_date, $plate, $note) = @_;
    my $exp_id;
    my $exp_obj = $schema->resultset('experiment')->find(
        {
            'exp_date' => $exp_date,
            'plate_no' => {'ilike' => $plate},
            'note' => {'ilike' => $note}
        }
    );
    if(!$exp_obj) {
        $exp_obj = $schema->resultset('experiment')->create(
            {
                'exp_date' => $exp_date,
                'plate_no' => $plate,
                'note' => $note
            }
        );
    }

    return $exp_obj->exp_id;
}

sub find_or_create_conc_id {
    my ($schema, $conc) = @_;
    my $conc_obj = $schema->resultset('titration_conc')->find_or_create({conc => $conc});
    return $conc_obj->conc_id;
}

sub find_or_create_blcl_id {
    my ($schema, $blcl) = @_;

    my $blcl_obj = $schema->resultset('blcl')->find({name => {'ilike' => $blcl}});
    if (!$blcl_obj) {
        $blcl_obj = $schema->resultset('blcl')->create({name => $blcl});
    }
    return $blcl_obj->blcl_id;
}

sub find_hla_id {
    my ($schema, $hla) = @_;
    my $hla_id = "";
    my $hla_obj = $schema->resultset('hla')->find({type => {'ilike' => $hla}});
    if ($hla_obj) {
        $hla_id = $hla_obj->hla_id;
    }
    return $hla_id;
}

sub get_pept_id {
    my ($schema, $pept_name, $pept_seq) = @_;
    my $pept_obj;
    my $pept_id = "";
    if ($pept_seq) {
        $pept_obj = $schema->resultset('peptide')->find(
            {
                sequence => $pept_seq
            }
        );
    }elsif ($pept_name) {
        $pept_obj = $schema->resultset('peptide')->find(
            {
                name => $pept_name
            }
        );
    }
    if ($pept_obj) {
        $pept_id = $pept_obj->pept_id;
    }
    return $pept_id;
}

sub get_pool_id {
    my ($schema, $pool_name) = @_;
    my $pool_obj;
    my $pool_id = "";

    $pool_obj = $schema->resultset('pool')->find(
        {
            name => {'ilike' => $pool_name}
        }
    );

    if ($pool_obj) {
        $pool_id = $pool_obj->pool_id;
    }
    return $pool_id;
}

sub get_cohort_id {
    my ($schema, $cohort) = @_;
    my $cohort_id = "";
    my $cohort_obj = ViroDB->instance->resultset('Cohort')->find({name => {'-ilike' => $cohort}});
    if ($cohort_obj) {
        $cohort_id = $cohort_obj->cohort_id;
    }
    return $cohort_id;
}

sub get_tissue_type_id {
    my ($schema, $tissue_type) = @_;
    my $tissue_type_id = "";
    my $tissue_type_obj = ViroDB->instance->resultset('TissueType')->find({name => {'-ilike' => $tissue_type}});
    if ($tissue_type_obj) {
        $tissue_type_id = $tissue_type_obj->tissue_type_id;
    }
    return $tissue_type_id;
}

sub get_patient_id {
    my ($schema, $cohort_id, $patient) = @_;
    my $patient_id = "";
    my $patient_obj = ViroDB->instance->resultset('Cohort')
        ->find($cohort_id)
        ->find_patient_by_alias($patient);
    if ($patient_obj) {
        $patient_id = $patient_obj->id;
    }
    return $patient_id;
}

sub get_visit_id {
    my ($schema, $patient_id, $sample_date) = @_;
    my $visit_id;
    my $visit_obj = ViroDB->instance->resultset('Visit')->find(
        {
            patient_id => $patient_id,
            visit_date => $sample_date
        }
    );
    if ($visit_obj) {
        $visit_id = $visit_obj->id;
    }
    return $visit_id;
}

sub get_sample_id {
    my ($schema, $visit_id, $tissue_type_id) = @_;
    my $sample_id;
    my $sample_obj = ViroDB->instance->resultset('Sample')->find(
        {
            tissue_type_id => $tissue_type_id,
            visit_id => $visit_id
        }
    );
    if ($sample_obj) {
        $sample_id = $sample_obj->id;
    }
    return $sample_id;
}

sub get_measure_id {
    my ($schema, $pept_id, $exp_id, $sample_id, $table) = @_;
    my $measure_id = "";
    my $measure_obj = $schema->resultset($table)->find(
        {
            pept_id => $pept_id,
            exp_id => $exp_id,
            sample_id => $sample_id
        }
    );
    if ($measure_obj) {
        $measure_id = $measure_obj->measure_id;
    }
    return $measure_id;
}


sub import_peptide {
    my ($schema, $fields) = @_;
    my $pept_obj = $schema->resultset('peptide')->create(
        {
            'name' => $fields->[0],
            'sequence' => $fields->[1],
            'gene_id' => $fields->[2],
            'position_hxb2_start' => $fields->[3],
            'position_hxb2_end' => $fields->[4],
            'origin_id' => $fields->[5]
        }
    );
}

sub get_peptide_pept_id {
    my ($schema, $pept_name, $pept_seq, $origin_id, $gene_id, $hxb2_start, $hxb2_end) = @_;

    my ($pept_id, $status);
    my $flag = 0;

    my $peptide_name_obj = $schema->resultset('peptide')->find(
        {
            'name' => $pept_name
        }
    );

    my $peptide_seq_obj = $schema->resultset('peptide')->find(
        {
            'sequence' => $pept_seq
        }
    );

    if ($peptide_name_obj) { # found peptide with same name in database
        $pept_id = $peptide_name_obj->pept_id;
        if ($pept_seq ne $peptide_name_obj->sequence) {
            $status->{seq} = "update";
            $flag = 1;
        }
        if ($origin_id != $peptide_name_obj->origin_id) {
            $status->{origin} = "update";
            $flag = 1;
        }
        if ($gene_id != $peptide_name_obj->gene_id) {
            $status->{region} = "update";
            $flag = 1;
        }
        if ($hxb2_start != $peptide_name_obj->position_hxb2_start) {
            $status->{hxb2_start} = "update";
            $flag = 1;
        }
        if ($hxb2_end != $peptide_name_obj->position_hxb2_end) {
            $status->{hxb2_end} = "update";
            $flag = 1;
        }
    }elsif ($peptide_seq_obj) { # found peptide with same sequence in database
        $pept_id = $peptide_seq_obj->pept_id;
        if ($pept_name ne $peptide_seq_obj->name) {
            $status->{name} = "update";
            $flag = 1;
        }
        if ($origin_id != $peptide_seq_obj->origin_id) {
            $status->{origin} = "update";
            $flag = 1;
        }
        if ($gene_id != $peptide_seq_obj->gene_id) {
            $status->{region} = "update";
            $flag = 1;
        }
        if ($hxb2_start != $peptide_seq_obj->position_hxb2_start) {
            $status->{hxb2_start} = "update";
            $flag = 1;
        }
        if ($hxb2_end != $peptide_seq_obj->position_hxb2_end) {
            $status->{hxb2_end} = "update";
            $flag = 1;
        }
    }else {
        $status = "new";
        $flag = 1;
        # import new data to peptide table
        $pept_id = $schema->resultset('peptide')->create(
            {
                'name' => $pept_name,
                'sequence' => $pept_seq,
                'origin_id' => $origin_id,
                'gene_id' => $gene_id,
                'position_hxb2_start' => $hxb2_start,
                'position_hxb2_end' => $hxb2_end
            }
        )->pept_id;
    }

    if ($flag == 0) {
        $status = "exist";
    }
    return ($pept_id, $status);
}

sub get_pool_pool_id {
    my ($schema, $pool_name, $pept_id) = @_;
    my ($pool_id, $status);

    my $pool_obj = $schema->resultset('pool')->find(
        {
            'name' => $pool_name
        }
    );
    if ($pool_obj) {
        $pool_id = $pool_obj->pool_id;
        my $pool_pept_obj = $schema->resultset('pool_pept')->find(
            {
                'pool_id' => $pool_id,
                'pept_id' => $pept_id
            }
        );
        if ($pool_pept_obj) {
            $status = "exist";
        }else {
            $status = "new";
        }
    }else {
        $status = "new";
        $pool_id = $schema->resultset('pool')->create({'name' => $pool_name})->pool_id;
    }

    if ($status eq "new") {
        $schema->resultset('pool_pept')->create(
            {
                'pool_id' => $pool_id,
                'pept_id' => $pept_id
            }
        );
    }
    return ($pool_id, $status);
}

sub get_eptp_id {
    my ($schema, $ept_pept_id, $source_id, $type) = @_;
    my ($eptp_id, $status);
    my $epitope_obj = $schema->resultset('epitope')->find(
        {
            'pept_id' => $ept_pept_id,
#            'source_id' => $source_id
        }
    );

    if ($epitope_obj) {
         $eptp_id = $epitope_obj->epit_id;
        my $epitope_source_obj = $schema->resultset('epitope')->find(
            {
                'pept_id' => $ept_pept_id,
                'source_id' => $source_id
            }
        );
        if ($epitope_source_obj) {
            $status = "exist" if ($type eq "epitope_result");
        }else {
            if ($type eq "epitope_result") {
                $status->{eptp} = "update";
            }else {    # mutant import, just update the epitope table
                update_epitope($schema, $eptp_id, $source_id);
            }
        }
    }else {
        $status = "new" if ($type eq "epitope_result");
        $eptp_id = $schema->resultset('epitope')->create(
            {
                'pept_id' => $ept_pept_id,
                'source_id' => $source_id
            }
        )->epit_id;
    }
    return ($eptp_id, $status);
}

sub get_mut_id {
    my ($schema, $mut_pept_id) = @_;
    my $mut_id = $schema->resultset('mutant')->find_or_create({'pept_id' => $mut_pept_id})->mutant_id;
    return $mut_id;
}

sub check_epitope_mutant {
    my ($schema, $eptp_id, $mut_id, $c) = @_;
    my $patient_id = $c->req->param('patient');
    my $note = $c->req->param('note');
    my $status;
    my $epitope_mutant_obj = $schema->resultset('epitope_mutant')->find(
        {
            'epit_id' => $eptp_id,
            'mutant_id' => $mut_id,
            'patient_id' => $patient_id
        }
    );
    if ($epitope_mutant_obj) {
        if ($note eq $epitope_mutant_obj->note) {
            $status = "exist";
        }else {
            $status->{mut} = "update";
        }
    }else {
        $status = "new";
        # import into epitope_mutant table
        $schema->resultset('epitope_mutant')->create(
            {
                'epit_id' => $eptp_id,
                'mutant_id' => $mut_id,
                'patient_id' => $patient_id,
                'note' => $note
            }
        );
    }
    return $status;
}

sub get_epitope_mutant_note {
    my ($schema, $eptp_id, $mut_id, $c) = @_;
    my $patient_id = $c->req->param('patient');
    my $note = $schema->resultset('epitope_mutant')->find(
        {
            'epit_id' => $eptp_id,
            'mutant_id' => $mut_id,
            'patient_id' => $patient_id
        }
    )->note;
    return $note;
}

sub get_pept_elispot_measure_id {
    my ($schema, $exp_id, $sample_id, $input_cell_num, $pept_id, $sfcs_ref) = @_;
    my $measure_id;
    my $status;
    my @sfcs = @{$sfcs_ref};
    @sfcs = sort {$a <=> $b} @sfcs;
    my $sfcs_str = join ("|", @sfcs);

    my $pept_response_obj = $schema->resultset('pept_response')->find(
        {
            'exp_id' => $exp_id,
            'sample_id' => $sample_id,
            'pept_id' => $pept_id
        }
    );

    if ($pept_response_obj) {
        $measure_id = $pept_response_obj->measure_id;
        my $exist_cell_num = $pept_response_obj->cell_num;

        my $reading_obj = $schema->resultset('reading')->search(
            {
                'measure_id' => $measure_id
            }
        );
        my @readings;
        while (my $readings = $reading_obj->next) {
            push @readings, $readings->value;
        }
        @readings = sort {$a <=> $b} @readings;
        my $readings_str = join ("|", @readings);
        if ($readings_str eq $sfcs_str && $exist_cell_num == $input_cell_num) {
            $status = "exist";
        }else {
            if ($readings_str ne $sfcs_str) {
                $status->{sfc} = "update";
            }
            if ($exist_cell_num != $input_cell_num) {
                $status->{cell} = "update";
            }
        }
    }else {
        $status = "new";
        $measure_id = $schema->resultset('pept_response')->create(
            {
                'exp_id' => $exp_id,
                'sample_id' => $sample_id,
                'cell_num' => $input_cell_num,
                'pept_id' => $pept_id
            }
        )->measure_id;
    }


    # add measure_id into measurement table if there is no one
    my $measure_obj = $schema->resultset('measurement')->find_or_create(
        {
            'measure_id' => $measure_id
        }
    );

    return ($measure_id, $status);
}

sub get_titration_measure_id {
    my ($schema, $exp_id, $sample_id, $input_cell_num, $pept_id, $conc_id, $sfcs_ref, $input_ec50) = @_;
    my $measure_id;
    my $status;
    my @sfcs = @{$sfcs_ref};
    @sfcs = sort {$a <=> $b} @sfcs;
    my $sfcs_str = join ("|", @sfcs);

    # check for particular measure in titration table
    my $titration_measure_obj = $schema->resultset('titration')->find(
        {
            'exp_id' => $exp_id,
            'sample_id' => $sample_id,
            'pept_id' => $pept_id,
            'conc_id' => $conc_id
        }
    );

    if ($titration_measure_obj) {
        $measure_id = $titration_measure_obj->measure_id;
        my $exist_ec50 = $titration_measure_obj->ec50;
        my $exist_cell_num = $titration_measure_obj->cell_num;

        # check for reading table for readings of the measure_id
        my $reading_obj = $schema->resultset('reading')->search(
            {
                'measure_id' => $measure_id
            }
        );
        my @readings;
        while (my $readings = $reading_obj->next) {
            push @readings, $readings->value;
        }
        @readings = sort {$a <=> $b} @readings;
        my $readings_str = join ("|", @readings);
        if ($readings_str eq $sfcs_str && $exist_cell_num == $input_cell_num && $exist_ec50 eq $input_ec50) {
            $status = "exist";
        }else {
            if ($readings_str ne $sfcs_str) {
                $status->{sfc} = "update";
            }
            if ($exist_cell_num != $input_cell_num) {
                $status->{cell} = "update";
            }
            if ($exist_ec50 ne $input_ec50) {
                $status->{ec50} = "update";
            }
        }
    }else {
        $status = "new";
        $measure_id = $schema->resultset('titration')->create(
            {
                'exp_id' => $exp_id,
                'sample_id' => $sample_id,
                'cell_num' => $input_cell_num,
                'pept_id' => $pept_id,
                'conc_id' => $conc_id,
                'ec50' => $input_ec50
            }
        )->measure_id;
    }


    # add measure_id into measurement table if there is no one
    my $measure_obj = $schema->resultset('measurement')->find_or_create(
        {
            'measure_id' => $measure_id
        }
    );

    return ($measure_id, $status);
}

sub get_hla_restriction_measure_id {
    my ($schema, $exp_id, $sample_id, $input_cell_num, $pept_id, $blcl_id, $sfcs_ref) = @_;
    my $measure_id;
    my $status;
    my @sfcs = @{$sfcs_ref};
    @sfcs = sort {$a <=> $b} @sfcs;
    my $sfcs_str = join ("|", @sfcs);

    # check for particular measure in hla_response table
    my $hla_response_measure_obj = $schema->resultset('hla_response')->find(
        {
            'exp_id' => $exp_id,
            'sample_id' => $sample_id,
            'pept_id' => $pept_id,
            'blcl_id' => $blcl_id
        }
    );

    if ($hla_response_measure_obj) {
        $measure_id = $hla_response_measure_obj->measure_id;
        my $exist_cell_num = $hla_response_measure_obj->cell_num;

        # check for reading table for readings of the measure_id
        my $reading_obj = $schema->resultset('reading')->search(
            {
                'measure_id' => $measure_id
            }
        );
        my @readings;
        while (my $readings = $reading_obj->next) {
            push @readings, $readings->value;
        }
        @readings = sort {$a <=> $b} @readings;
        my $readings_str = join ("|", @readings);
        if ($readings_str eq $sfcs_str && $exist_cell_num == $input_cell_num) {
            $status = "exist";
        }else {
            if ($readings_str ne $sfcs_str) {
                $status->{sfc} = "update";
            }
            if ($exist_cell_num != $input_cell_num) {
                $status->{cell} = "update";
            }
        }
    }else {
        $status = "new";
        $measure_id = $schema->resultset('hla_response')->create(
            {
                'exp_id' => $exp_id,
                'sample_id' => $sample_id,
                'cell_num' => $input_cell_num,
                'pept_id' => $pept_id,
                'blcl_id' => $blcl_id,
            }
        )->measure_id;
    }

    # add measure_id into measurement table if there is no one
    my $measure_obj = $schema->resultset('measurement')->find_or_create(
        {
            'measure_id' => $measure_id
        }
    );

    return ($measure_id, $status);
}

sub get_pool_elispot_measure_id {
    my ($schema, $exp_id, $sample_id, $input_cell_num, $pool_id, $sfcs_ref, $input_matrix_index) = @_;
    $input_matrix_index = '' unless $input_matrix_index;
    my $measure_id;
    my $status;
    my @sfcs = @{$sfcs_ref};
    @sfcs = sort {$a <=> $b} @sfcs;
    my $sfcs_str = join ("|", @sfcs);

    my $pool_response_obj = $schema->resultset('pool_response')->find(
        {
            'exp_id' => $exp_id,
            'sample_id' => $sample_id,
            'matrix_index' => $input_matrix_index,
            'pool_id' => $pool_id
        }
    );

#    warn "pool_response_obj: $pool_response_obj\n";

    if ($pool_response_obj) {
        $measure_id = $pool_response_obj->measure_id;
        my $exist_cell_num = $pool_response_obj->cell_num;

        my $reading_obj = $schema->resultset('reading')->search(
            {
                'measure_id' => $measure_id
            }
        );
        my @readings;
        while (my $readings = $reading_obj->next) {
            push @readings, $readings->value;
        }
        @readings = sort {$a <=> $b} @readings;
        my $readings_str = join ("|", @readings);
        if ($readings_str eq $sfcs_str && $exist_cell_num == $input_cell_num) {
            $status = "exist";
        }else {
            if ($readings_str ne $sfcs_str) {
                $status->{sfc} = "update";
            }
            if ($exist_cell_num != $input_cell_num) {
                $status->{cell} = "update";
            }
        }
    }else {
        $status = "new";
        $measure_id = $schema->resultset('pool_response')->create(
            {
                'exp_id' => $exp_id,
                'sample_id' => $sample_id,
                'cell_num' => $input_cell_num,
                'matrix_index' => $input_matrix_index,
                'pool_id' => $pool_id
            }
        )->measure_id;
    }


    # add measure_id into measurement table if there is no one
    my $measure_obj = $schema->resultset('measurement')->find_or_create(
        {
            'measure_id' => $measure_id
        }
    );

    return ($measure_id, $status);
}

sub add_hla_pept {
    my ($schema, $pept_id, $hla_id) = @_;
    $schema->resultset('hla_pept')->find_or_create(
        {
            'hla_id' => $hla_id,
            'pept_id' => $pept_id
        }
    );
    return 1;
}

sub get_cell_num {
    my ($schema, $measure_id, $type) = @_;
    my $measure_obj = $schema->resultset($type)->find(
        {
            'measure_id' => $measure_id
        }
    );
    return $measure_obj->cell_num;
}

sub get_ec50 {
    my ($schema, $measure_id, $type) = @_;
    my $measure_obj = $schema->resultset($type)->find(
        {
            'measure_id' => $measure_id
        }
    );
    return $measure_obj->ec50;
}

sub get_source_by_eptp_id {
    my ($schema, $eptp_id) = @_;
    my $epitope_obj = $schema->resultset('epitope')->search(
        {'me.epit_id' => $eptp_id},
        {
            join => 'source',
            prefetch => 'source'
        }
    );
    my $epitope = $epitope_obj->next;
    my $source_id = $epitope->source->source_id;
    my $source = $epitope->source->source;
    my $source_obj = {
        source_id => $source_id,
        source => $source
    };
    return $source_obj;
}

sub get_source_by_source_id {
    my ($schema, $source_id) = @_;
    my $source_obj = $schema->resultset('source')->find(
        {
            'source_id' => $source_id
        }
    );
    my $source = $source_obj->source;
    my $source_obj_inp = {
        source_id => $source_id,
        source => $source
    };
    return $source_obj_inp;
}

sub find_pept_attrs_by_pept_id {
    my ($schema, $pept_id, $attr) = @_;
    my $pept_obj = $schema->resultset('peptide')->find({pept_id => $pept_id});
    return $pept_obj->$attr;
}

sub get_origin_by_pept_id {
    my ($schema, $pept_id) = @_;
    my $pept_obj = $schema->resultset('peptide')->search(
        {'me.pept_id' => $pept_id},
        {
            join => 'origin',
            prefetch => 'origin'
        }
    );
    my $peptide = $pept_obj->next;
    my $origin_obj = {
        origin_id => $peptide->origin_id,
        origin => $peptide->origin->name
    };
    return $origin_obj;
}

sub get_origin_by_origin_id {
    my ($schema, $origin_id) = @_;
    my $origin_obj = $schema->resultset('origin')->find({'origin_id' => $origin_id});
    my $origin_obj_inp = {
        origin_id => $origin_id,
        origin => $origin_obj->name
    };
    return $origin_obj_inp;
}

sub get_gene_by_pept_id {
    my ($schema, $pept_id) = @_;
    my $pept_obj = $schema->resultset('peptide')->search(
        {'me.pept_id' => $pept_id},
        {
            join => 'gene',
            prefetch => 'gene'
        }
    );
    my $peptide = $pept_obj->next;
    my $gene_obj = {
        gene_id => $peptide->gene_id,
        gene => $peptide->gene->gene_name
    };
    return $gene_obj;
}

sub get_gene_by_gene_id {
    my ($schema, $gene_id) = @_;
    my $gene_obj = $schema->resultset('gene')->find({'gene_id' => $gene_id});
    my $gene_obj_inp = {
        gene_id => $gene_id,
        gene => $gene_obj->gene_name
    };
    return $gene_obj_inp;
}

sub update_peptide {
    my ($schema, $pept_id, $update_value, $column) = @_;
    my $pept_obj = $schema->resultset('peptide')->find({'pept_id' => $pept_id});
    $pept_obj->update({$column => $update_value});
#    print "pept_id: $pept_id, value: $update_value, column: $column\n";
}

sub update_epitope {
    my ($schema, $c) = @_;
    my $eptp_id = $c->req->param('eptp_id');
    my $source_id = $c->req->param('source_id');
    my $epitope_obj = $schema->resultset('epitope')->find({'epit_id' => $eptp_id});
    $epitope_obj->update({'source_id' => $source_id});
}

sub update_epitope_mutant {
    my ($schema, $c) = @_;
    my $eptp_id = $c->req->param('eptp_id');
    my $mut_id = $c->req->param('mut_id');
    my $patient_id = $c->req->param('patient_id');
    my $note = $c->req->param('note');
    warn "note: $note";
    my $epitope_mutant_obj = $schema->resultset('epitope_mutant')->find(
        {
            'epit_id' => $eptp_id,
            'mutant_id' => $mut_id,
            'patient_id' => $patient_id
        }
    );
    $epitope_mutant_obj->update({'note' => $note});
}

sub get_reading {
    my ($schema, $measure_id) = @_;
    my @readings;
    my $reading_obj = $schema->resultset('reading')->search(
        {
            'measure_id' => $measure_id
        }
    );

    while (my $reading = $reading_obj->next) {
        push @readings, $reading->value;
    }
    return @readings;
}

sub add_readings {
    my ($schema, $measure_id, $sfcs_ref) = @_;
    foreach my $sfc (@$sfcs_ref) {
        $schema->resultset('reading')->create (
            {
                'measure_id' => $measure_id,
                'value' => $sfc,
            }
        );
    }
}

sub update_readings {
    my ($schema, $measure_id, $sfcs_ref) = @_;
    my $reading_obj = $schema->resultset('reading')->search(
        {
            'measure_id' => $measure_id
        }
    );

    $reading_obj->delete;

    add_readings($schema, $measure_id, $sfcs_ref);
}

sub update_cell_num {
    my ($schema, $type, $measure_id, $input_cell_num) = @_;
    my $measure_obj = $schema->resultset($type)->find({'measure_id' => $measure_id});
    $measure_obj->update({'cell_num' => $input_cell_num});
}

sub update_ec50 {
    my ($schema, $type, $measure_id, $input_ec50) = @_;
    my $measure_obj = $schema->resultset($type)->find({'measure_id' => $measure_id});
    $measure_obj->update({'ec50' => $input_ec50});
}



1;

__END__


=head1 AUTHOR

Wenjie E<lt>dengw@u.washington.eduE<gt>

=head1 COPYRIGHT AND LICENSE

This code was developed under funding from WA State ATI.

=cut

