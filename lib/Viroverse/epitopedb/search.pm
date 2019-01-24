package Viroverse::epitopedb::search;

use strict;
use warnings;
use Data::Dump;
use Carp;
use Storable;
use Time::HiRes qw[time];

my $neg_id = 1;
my $pha_id = 2;
my $cef_id = 3;

sub get_genes {

    my ($schema) = @_;
    my @genes = $schema->resultset('gene')->all;
    return \@genes;
}

sub get_sources {

    my ($schema) = @_;
    my @sources = $schema->resultset('source')->search(
        undef,
        {
            order_by => ['source']
        }
    );
    return \@sources;
}
sub get_hlas {

    my ($schema) = @_;
    my @hlas = $schema->resultset('hla')->all;
    return \@hlas;
}

sub get_patients {
    my ($schema) = @_;
    my @patients = $schema->resultset('test_patient')->search(
        {},
        {order_by => ['patient']}
    );
    return \@patients;
}

sub get_origins {

    my ($schema) = @_;
    my @origins = $schema->resultset('origin')->search(
        undef,
        {
            order_by => ['name']
        }
    );
    return \@origins;
}

sub get_pools {
    my ($schema) = @_;
    my @pools = $schema->resultset('pool')->search(
        {},
        {
            order_by => ['name']
        }
    );
    return \@pools;
}

sub pept_search {
    my ($c, $schema) = @_;

    my @pept_genes = $c->req->param('pept_gene');
    my @epit_genes = $c->req->param('epit_gene');
    my @sources = $c->req->param('source');
    my $pept_name = uc $c->req->param('pept_name') 
        if (defined $c->req->param('pept_name') && $c->req->param('pept_name') ne "-- None --");
    my $pept_seq = uc $c->req->param('pept_seq')
        if (defined $c->req->param('pept_seq') && $c->req->param('pept_seq') ne "-- None --");
    my $lengtha = $c->req->param('lengtha')
        if (defined $c->req->param('lengtha') && $c->req->param('lengtha') ne "-- None --");
    my $lengthb = $c->req->param('lengthb')
        if (defined $c->req->param('lengthb') && $c->req->param('lengthb') ne "-- None --");
    my @hlas = $c->req->param('hla');
    my @patients = $c->req->param('patient');

    my $cond = my $attrs = ();

    if(@pept_genes) {
        unless ($pept_genes[0] == 1) {
            $cond->{'gene.gene_id'} = {'-in' => \@pept_genes};
        }
    }elsif(@epit_genes) {
        unless ($epit_genes[0] == 1) {
            $cond->{'gene.gene_id'} = {'-in' => \@epit_genes};
        }
        if (@sources) {
            unless ($sources[0] == 1) {
                $cond->{'source.source_id'} = {'-in' => \@sources};
            }
        }
    }
    if (@hlas) {
        unless ($hlas[0] == 0) {
            $cond->{'prc_hp_hla.hla_id'} = {'-in' => \@hlas};
        }
    }

    if (@patients) {
        unless ($patients[0] == 0) {
            $cond->{'pept_response_corravg.patient_id'} = {'-in' => \@patients};
        }
    }

    if ($pept_name) {
        if (@epit_genes) {
            $cond->{'peptide.name'} = $pept_name;
        }else {
            $cond->{'me.name'} = $pept_name;
        }
    }elsif ($pept_seq) {
        if (@epit_genes) {
            $cond->{'peptide.sequence'} = $pept_seq;
        }else {
            $cond->{'me.sequence'} = $pept_seq;
        }
    }elsif ($lengtha && $lengthb) {
        if (@epit_genes) {
            $cond->{'length(peptide.sequence)'} = {    '<=' => $lengthb,
                                            '>=' => $lengtha
                                            };
        }else {
            $cond->{'length(me.sequence)'} = {    '<=' => $lengthb,
                                            '>=' => $lengtha
                                            };
        }
    }elsif ($lengtha) {
        if (@epit_genes) {
            $cond->{'length(peptide.sequence)'} = {'>=' => $lengtha};
        }else {
            $cond->{'length(me.sequence)'} = {'>=' => $lengtha};
        }
    }elsif ($lengthb) {
        if (@epit_genes) {
            $cond->{'length(peptide.sequence)'} = {'<=' => $lengthb};
        }else {
            $cond->{'length(me.sequence)'} = {'<=' => $lengthb};
        }
    }

    my @rs;
    if (@epit_genes) {
        $attrs = {
            select => [ 'me.pept_id', 
                        'peptide.name',
                        'peptide.sequence',
                        'peptide.position_hxb2_start',
                        'peptide.position_hxb2_end',
                        'source.source',
                        'left_join_test_patient.patient_id', 
                        'left_join_test_patient.patient', 
                        {MAX => 'pept_response_corravg.corr_avg'},
                        {MIN => 'prc_titration_corravg.ec50'},
                        {COUNT => 'prc_hla_response_corravg.pept_id'},
                    ],
            as => [qw/pept_id name seq hxb2_start hxb2_end source patient_id patient max min count/],
            join => [     'source',
                        {'peptide' => ['gene']},
                        {'pept_response_corravg' => [qw/left_join_test_patient prc_titration_corravg prc_hla_response_corravg/, {'prc_hla_pept' => 'prc_hp_hla'}]}
                    ],
            group_by => [qw/me.pept_id peptide.name peptide.sequence peptide.position_hxb2_start peptide.position_hxb2_end 
                        source.source left_join_test_patient.patient_id gene.gene_id left_join_test_patient.patient/],
            order_by => [qw/gene.gene_id peptide.position_hxb2_start peptide.name left_join_test_patient.patient/],
        };

        @rs = $schema->resultset('epitope')->search($cond, $attrs);
    }else {
        $attrs = {
            select => [ 'me.pept_id',
                        'me.name',
                        'me.sequence',
                        'me.position_hxb2_start',
                        'me.position_hxb2_end',
                        'test_patient.patient_id', 
                        'test_patient.patient',
                        {MAX => 'pept_response_corravg.corr_avg'},
                        {MIN => 'prc_titration_corravg.ec50'},
                        {COUNT => 'prc_hla_response_corravg.pept_id'},
                    ],
            as => [qw/pept_id name seq hxb2_start hxb2_end patient_id patient max min count/],
            join => [    'gene',
                        {'pept_response_corravg' => [qw/test_patient prc_titration_corravg prc_hla_response_corravg/, {'prc_hla_pept' => 'prc_hp_hla'}]}
                    ],

            group_by => [qw/me.pept_id me.name me.sequence me.position_hxb2_start me.position_hxb2_end 
                        test_patient.patient_id gene.gene_id test_patient.patient/],
            order_by => [qw/gene.gene_id me.position_hxb2_start me.name test_patient.patient/],
        };
        @rs = $schema->resultset('peptide')->search($cond, $attrs);
    }

    my @retrs;
    foreach my $rs (@rs) {
        my $pept_id = $rs->pept_id;
        my $peptide = $rs->get_column('name');
        my $sequence = $rs->get_column('seq');
        my $hxb2_start = $rs->get_column('hxb2_start');
        my $hxb2_end = $rs->get_column('hxb2_end');
        my $patient_id = $rs->get_column('patient_id');
        my $patient = $rs->get_column('patient');
        my $max_corravg = "";
        if (defined $rs->get_column('max')) {
            $max_corravg = int ($rs->get_column('max') * 100 + 0.5) / 100;
        }
        my $min_ec50 = "";
        if ($rs->get_column('min')) {
            if ($rs->get_column('min') eq "undef") {
                $min_ec50 = "undef";
            }elsif ($rs->get_column('min') eq "uncal") {
                $min_ec50 = "uncal";
            }else {
                $min_ec50 = int ($rs->get_column('min') * 10000 + 0.5) / 10000;
            }
        }

        my $hr_result = "";
        if ($rs->get_column('count') > 0) {
            $hr_result = "Result";
        }

        # get hla types for the peptide in any
        my @hla_rs = $schema->resultset('hla_pept')->search(
            {'pept_id' => $pept_id},
            {
                join => ['hla'],
                prefetch => ['hla']
            }
        );
        my $hla_type = "";
        foreach my $hla_rs (@hla_rs) {
            if ($hla_type) {
                $hla_type .= ", ";
            }
            $hla_type .= $hla_rs->hla->type;
        }

        # get number of mutants for the peptide if any
        my $mt_rs = $schema->resultset('epitope_mutant')->search(
            {    'epitope.pept_id' => $pept_id,
                'me.patient_id' => $patient_id
            },
            {
                join => ['epitope'],
            }
        );

        my $mutant = "";
        if ($mt_rs != 0) {
            $mutant = $mt_rs->get_column('mutant_id')->func('COUNT');
        }
        my $retrs = {
            pept_id => $pept_id,
            peptide => $peptide,
            sequence => $sequence,
            position_hxb2_start => $hxb2_start,
            position_hxb2_end => $hxb2_end,
            patient => $patient,
            patient_id => $patient_id,
            max_corravg => $max_corravg,
            min_ec50 => $min_ec50,
            hla => $hla_type,
            hla_response => $hr_result,
            mutant => $mutant
        };
        if (@epit_genes) {
            $retrs->{source} = $rs->get_column('source');
        }
        push @retrs, $retrs;
    }
    return \@retrs;
}


sub pool_search {
    my ($c, $schema) = @_;

    my $pept_name = uc $c->req->param('pept_name');
    my $pept_seq = uc $c->req->param('pept_seq');
    my @pools = $c->req->param('pool');
    warn "pept_name: $pept_name, seq: $pept_seq\n";
    my $cond = my $attrs = ();

    if ($pept_name && $pept_name ne "-- NONE --") {
        $cond->{'me.name'} = $pept_name;
    }elsif ($pept_seq && $pept_seq ne "-- NONE --") {
        $cond->{'me.sequence'} = $pept_seq;
    }elsif (@pools) {
        unless ($pools[0] == 0) {
            $cond->{'me.pool_id'} = {'-in' => \@pools};
        }
    }

    my @rs;
    if (($pept_name && ($pept_name ne "-- NONE --")) || ($pept_seq && ($pept_seq ne "-- NONE --"))) {
        warn "peptied\n";
        $attrs = {
            select => [ 'pool.pool_id', 
                        'pool.name',
                        'sample.patient_id', 
                        'sample.patient', 
                        {MAX => 'pool_response_corravg.corr_avg'},
                    ],
            as => [qw/pool_id name patient_id patient max/],
            join => [     {'pool_pept' => [
                                            {'pool' =>     [
                                                            {'pool_response_corravg' => ['sample']}
                                                        ]
                                            }
                                        ]
                        },
                    ],

            group_by => [qw/pool.pool_id pool.name sample.patient_id sample.patient/],
            order_by => [qw/pool.name/],
        };
        @rs = $schema->resultset('peptide')->search($cond, $attrs);
    }else {
        warn "Pool\n";
        $attrs = {
            select => [ 'me.pool_id', 
                        'me.name',
                        'sample.patient_id', 
                        'sample.patient', 
                        {MAX => 'pool_response_corravg.corr_avg'},
                    ],
            as => [qw/pool_id name patient_id patient max/],
            join => [ 
                        {'pool_response_corravg' => ['sample']}
                    ],
            group_by => [qw/me.pool_id me.name sample.patient_id sample.patient/],
            order_by => [qw/me.name/],
        };
        @rs = $schema->resultset('pool')->search($cond, $attrs);
    }

    my @retrs;
    foreach my $rs (@rs) {
        my $pool_id = $rs->get_column('pool_id');
        my $name = $rs->get_column('name');
        my $patient_id = $rs->get_column('patient_id');
        my $patient = $rs->get_column('patient');
        my $max_corravg = "";
        if (defined $rs->get_column('max')) {
            $max_corravg = int ($rs->get_column('max') * 100 + 0.5) / 100;
        }

#        warn "id: $pool_id, name: $name, patient: $patient, max: $max_corravg\n";
#        next;

        # get peptides in the pool
        my @pept_rs = $schema->resultset('pool_pept')->search(
            {'pool_id' => $pool_id},
            {
                join => ['peptide'],
                prefetch => ['peptide']
            }
        );
        my $peptides = "";
        foreach my $pept_rs (@pept_rs) {
            if ($peptides) {
                $peptides .= ", ";
            }
            # XXX FIXME: Yet another SQL injection vulnerability in ancient code...
            #   -trs, 2 March 2017
            $peptides .= '<abbr title="' . $pept_rs->peptide->sequence . '">' . $pept_rs->peptide->name . '</abbr>';
        }
#        warn "peptides: $peptides\n";
        my $retrs = {
            pool_id => $pool_id,
            name => $name,
            patient => $patient,
            patient_id => $patient_id,
            max_corravg => $max_corravg,
            peptides => $peptides
        };
        push @retrs, $retrs;
    }
    return \@retrs;
}

sub get_exp_date {
    my ($c, $schema) = @_;
    my $exp_id = $c->req->param('exp_id');
    my $rs = $schema->resultset('experiment')->search(
        {'exp_id' => $exp_id},
        {}
    );
    my $retrs = { exp_date => $rs->next->exp_date };
    return $retrs;
}

sub get_sample {
    my ($c, $schema) = @_;
    my $sample_id = $c->req->param('sample_id');
    my @rs = $schema->resultset('sample')->search(
        {'sample_id' => $sample_id},
        {}
    );
    my $retrs;
    foreach my $rs (@rs) {
        $retrs = {
            sample_date => $rs->sample_date,
            tissue => $rs->tissue,
            patient => $rs->patient
        }
    }
    return $retrs;
}

sub get_pept {
    my ($c, $schema) = @_;
    my $pept_id = $c->req->param('pept_id');
    my @rs = $schema->resultset('peptide')->search(
        {'me.pept_id' => $pept_id},
        {prefetch => [qw/origin/]}
    );
    my $retrs;
    foreach my $rs (@rs) {
        $retrs = {
            peptide => $rs->name,
            sequence => $rs->sequence,
            origin => $rs->origin->name
        }
    }
    return $retrs;
}

sub get_patient {
    my ($c, $schema) = @_;
    my $patient_id = $c->req->param('patient_id');
    my $rs = $schema->resultset('test_patient')->search(
        {'patient_id' => $patient_id},
        {}
    );
    my $retrs = { patient => $rs->next->patient };
    return $retrs;
}

sub get_pool_name {
    my ($c, $schema) = @_;
    my $pool_id = $c->req->param('pool_id');
    my $rs = $schema->resultset('pool')->search(
        {'pool_id' => $pool_id},
        {}
    );
    my $retrs = { pool => $rs->next->name };
    return $retrs;
}

sub get_matrix {
    my ($c, $schema) = @_;
    my $exp_id = $c->req->param('exp_id');
    my $sample_id = $c->req->param('sample_id');
    my $matrix_index = $c->req->param('matrix_index');
    my @rs = $schema->resultset('pool_response')->search(
        {
            -and => [
                        {'me.exp_id' => $exp_id},
                        {'me.sample_id' => $sample_id},
                        {'me.matrix_index' => $matrix_index}
                    ]
        },
        {
            join => ['pool', 'pool_response_corravg'],
            order_by => ['pool.name']
        }
    );
    my (@pools, %poolResult, %poolName, %peptName, %peptSeq);
    my $pool_peptid = my $poolPeptResult = ();
    foreach my $rs (@rs) {
        my $pool = $rs->pool_id;
        my $pool_name = $rs->pool->name;
        my $result = $rs->pool_response_corravg->result;
        $poolName{$pool} = $pool_name;
        push @pools, $pool;
        $poolResult{$pool} = $result;
        warn "pool: $pool, result: $result\n";
        my @pept_rs = $schema->resultset('pool_pept')->search(
            {'me.pool_id' => $pool},
            {
                join => ['peptide'],
            }
        );
        my @peptids;
        foreach my $pept_rs (@pept_rs) {
            my $pept_id = $pept_rs->pept_id;
            my $peptName = $pept_rs->peptide->name;
            my $peptSeq = $pept_rs->peptide->sequence;
            $peptName{$pept_id} = $peptName;
            $peptSeq{$pept_id} = $peptSeq;
            $poolPeptResult->{$pool}->{$pept_id} = $result;
            push @peptids, $pept_id; 
        }
        $pool_peptid->{$pool} = \@peptids;
    }

    my (@h_pools, @v_pools, %peptidStatus);
    my $i = 0;
    foreach my $pool (@pools) {
        my @peptids = @{$pool_peptid->{$pool}};
        if ($i == 0) {
            push @h_pools, $pool;
            foreach (@peptids) {
                $peptidStatus{$_} = 1;
            }
            $i++;
        }else {
            my $flag = 0;
            foreach my $peptid (@peptids) {
                if ($peptidStatus{$peptid}) {
                    push @v_pools, $pool;
                    $flag = 1;
                    last;
                }
            }
            if (!$flag) {
                push @h_pools, $pool;
                foreach (@peptids) {
                    $peptidStatus{$_} = 1;
                }
            }
        }
    }
#    warn "h_pools: @h_pools\n";
#    warn "v_pools: @v_pools\n";
    my (@retrs, @single_retrs);
    my $single_rs = ();
    # first output line for matrix which consists of pool names
    $single_rs = {
        id => "",
        name => "",
        result => ""
    };
    push @single_retrs, $single_rs;
    for (my $i = 0; $i < scalar @v_pools; $i++) {
        $single_rs = {
            id => $v_pools[$i],
            name => $poolName{$v_pools[$i]},
            result => $poolResult{$v_pools[$i]},
        };
        push @single_retrs, $single_rs;
    }
    push @retrs, \@single_retrs;

    # following lines of matrix
    foreach my $h_pool (@h_pools) {
        my @single_retrs;
        my $single_rs = ();
        my @pept_ids = @{$pool_peptid->{$h_pool}};
        $single_rs = {
            id => $h_pool,
            name => $poolName{$h_pool},
            result => $poolResult{$h_pool},
        };
        push @single_retrs, $single_rs;

        my %pept_id_status;
        foreach my $v_pool (@v_pools) {
#            $single_rs = ();
            foreach my $pept_id (@pept_ids) {
                if (defined $poolPeptResult->{$v_pool}->{$pept_id}) {
                    my $result = $poolPeptResult->{$h_pool}->{$pept_id}.$poolPeptResult->{$v_pool}->{$pept_id};
                    $single_rs = {
                        id => $pept_id,
                        name => $peptName{$pept_id},
                        sequence => $peptSeq{$pept_id},
                        result => $result,
                    };

                    $pept_id_status{$pept_id} = 1;
                    last;
                }else {
                    $single_rs = {
                        id => "",
                        name => "",
                        sequence => "",
                        result => "",
                    };
                }
            }
            push @single_retrs, $single_rs;
        }
        foreach my $pept_id (@pept_ids) {
            if (!$pept_id_status{$pept_id}) {
                $single_rs = {
                    id => $pept_id,
                    name => $peptName{$pept_id},
                    sequence => $peptSeq{$pept_id},
                    result => "N",
                };
                push @single_retrs, $single_rs;
            }
        }
        push @retrs, \@single_retrs;
    }
    return \@retrs;
}

sub get_elispot {
    my ($c, $schema) = @_;

    my $pept_id = $c->req->param('pept_id');
    my $patient_id = $c->req->param('patient_id');

    my $pr_rs = $schema->resultset('reading')->search(
        {
            -and => [
                    'sample.patient_id' => $patient_id
                    -or => [
                        'peptide.pept_id' => $neg_id,
                        'peptide.pept_id' => $pha_id,
                        'peptide.pept_id' => $cef_id,
                        'peptide.pept_id' => $pept_id
                    ]
                ],
        },
        {
            join => {'pept_response' => [qw/peptide sample experiment pept_response_corravg/]},
            prefetch => {'pept_response' => [qw/peptide sample experiment pept_response_corravg/]},
            order_by => [qw/experiment.exp_date sample.sample_date peptide.pept_id/]
        }
    );

    my $rs = ();
    my (@retrs, %exp_date);
    while (my $reading_rs = $pr_rs->next) {
        my $exp_id = $reading_rs->pept_response->experiment->exp_id;
        my $exp_date = $reading_rs->pept_response->experiment->exp_date;
        my $pept_id = $reading_rs->pept_response->pept_id;
        my $sample_id = $reading_rs->pept_response->sample->sample_id;
        my $peptide = $reading_rs->pept_response->peptide->name;
        my $value = $reading_rs->value;
        $exp_date{$exp_id} = $exp_date;
#        warn "exp_date: $exp_date, peptide: $peptide, value: $value\n";

        $rs->{$exp_id}->{$sample_id}->{$pept_id}->{exp_date} = $exp_date if (!defined $rs->{$exp_id}->{$sample_id}->{$pept_id}->{exp_date});
        $rs->{$exp_id}->{$sample_id}->{$pept_id}->{peptide} = $peptide if (!defined $rs->{$exp_id}->{$sample_id}->{$pept_id}->{peptide});
        $rs->{$exp_id}->{$sample_id}->{$pept_id}->{sample_patient} = $reading_rs->pept_response->sample->patient if (!defined $rs->{$exp_id}->{$sample_id}->{$pept_id}->{sample_patient});
        $rs->{$exp_id}->{$sample_id}->{$pept_id}->{sample_date} = $reading_rs->pept_response->sample->sample_date if (!defined $rs->{$exp_id}->{$sample_id}->{$pept_id}->{sample_date});
        $rs->{$exp_id}->{$sample_id}->{$pept_id}->{sample_tissue} = $reading_rs->pept_response->sample->tissue if (!defined $rs->{$exp_id}->{$sample_id}->{$pept_id}->{sample_tissue});
        $rs->{$exp_id}->{$sample_id}->{$pept_id}->{cell_num} = $reading_rs->pept_response->cell_num if (!defined $rs->{$exp_id}->{$sample_id}->{$pept_id}->{cell_num});
        $rs->{$exp_id}->{$sample_id}->{$pept_id}->{avg} = $reading_rs->pept_response->pept_response_corravg->avg if (!defined $rs->{$exp_id}->{$sample_id}->{$pept_id}->{avg});
        $rs->{$exp_id}->{$sample_id}->{$pept_id}->{corr_avg} = $reading_rs->pept_response->pept_response_corravg->corr_avg if (!defined $rs->{$exp_id}->{$sample_id}->{$pept_id}->{corr_avg});

        if (!defined $rs->{$exp_id}->{$sample_id}->{$pept_id}->{value}) {
            $rs->{$exp_id}->{$sample_id}->{$pept_id}->{value} = ();
        }
        push @{$rs->{$exp_id}->{$sample_id}->{$pept_id}->{value}}, $value;
    }

    foreach my $exp_id (sort{ $exp_date{$a} cmp $exp_date{$b} } keys %exp_date) {
        foreach my $sample_id (sort keys %{$rs->{$exp_id}}) {
            if (defined $rs->{$exp_id}->{$sample_id}->{$pept_id}) {
                my @readings;
                my $neg_se = "";
                foreach my $my_pept_id (sort{$a<=>$b} keys %{$rs->{$exp_id}->{$sample_id}}) {
                    my $stdev = my $cv = my $se = my $corr_se = my $se_per = "";
                    my $sfc = int ($rs->{$exp_id}->{$sample_id}->{$my_pept_id}->{corr_avg} * 1000000 / $rs->{$exp_id}->{$sample_id}->{$my_pept_id}->{cell_num} * 10 + 0.5) / 10;
                    if (scalar @{$rs->{$exp_id}->{$sample_id}->{$my_pept_id}->{value}} > 1) {
                        $stdev = get_stdev($rs->{$exp_id}->{$sample_id}->{$my_pept_id}->{value}, $rs->{$exp_id}->{$sample_id}->{$my_pept_id}->{avg});
                        $cv = get_cv($stdev, $rs->{$exp_id}->{$sample_id}->{$my_pept_id}->{avg});
                        $se = int ($stdev / sqrt(2) * 10 + 0.5) / 10;

                        if ($my_pept_id == 1) {
                            $neg_se = $se;
                        }else {
                            if ($neg_se ne "") {
                                $corr_se = int (sqrt($se*$se + $neg_se*$neg_se) * 10 + 0.5) / 10;
                                $se_per = int (($corr_se * sqrt(1000000 / $rs->{$exp_id}->{$sample_id}->{$my_pept_id}->{cell_num})) * 10 + 0.5) / 10;
                            }
                        }
                    }

                    my $single_reading = {
                        exp_date => $rs->{$exp_id}->{$sample_id}->{$my_pept_id}->{exp_date},
                        peptide => $rs->{$exp_id}->{$sample_id}->{$my_pept_id}->{peptide},
                        sample_patient => $rs->{$exp_id}->{$sample_id}->{$my_pept_id}->{sample_patient},
                        sample_date => $rs->{$exp_id}->{$sample_id}->{$my_pept_id}->{sample_date},
                        sample_tissue => $rs->{$exp_id}->{$sample_id}->{$my_pept_id}->{sample_tissue},
                        cell_num => $rs->{$exp_id}->{$sample_id}->{$my_pept_id}->{cell_num},
                        avg => int ($rs->{$exp_id}->{$sample_id}->{$my_pept_id}->{avg} * 10 + 0.5) / 10,
                        corr_avg => int ($rs->{$exp_id}->{$sample_id}->{$my_pept_id}->{corr_avg} * 10 + 0.5) / 10,
                        stdev => $stdev,
                        cv => $cv,
                        se => $se,
                        corr_se => $corr_se,
                        se_per => $se_per,
                        sfc => $sfc,
                        value => join(", ", @{$rs->{$exp_id}->{$sample_id}->{$my_pept_id}->{value}})
                    };
                    push @readings, $single_reading;
                }
                push @retrs, \@readings;
            }else {
                last;
            }
        }
    }
    return \@retrs;
}


sub get_pool_elispot {
    my ($c, $schema) = @_;

    my $pool_id = $c->req->param('pool_id');
    my $patient_id = $c->req->param('patient_id');
    # get all exp_id and sample_id for the selected peptide and patient_id
    my @measure_rs = $schema->resultset('pool_response_corravg')->search(
        {
            'me.pool_id' => $pool_id,
            'sample.patient_id' => $patient_id
        },
        {
#            select => [qw/me.pept_id me.exp_id me.sample_id/],
            join => [qw/sample/],
#            group_by => [qw/me.pept_id me.exp_id me.sample_id/]
        }
    );

    my @retrs;
    foreach my $measure_rs (@measure_rs) {    # go through each distinct exp_id and sample_id
        my @readings; 
        my $exp_id = $measure_rs->exp_id;
        my $sample_id = $measure_rs->sample_id;
        my $measure_id = $measure_rs->measure_id;
#        warn "pept_id: $pept_id, exp_id: $exp_id, sample_id: $sample_id\n";

        # get negative and positive control sfc for paticular exp_id and sample_id
        my @reading_rs = $schema->resultset('reading')->search(
            {
                -and => [
                    'pept_response.exp_id' => $exp_id,
                    'pept_response.sample_id' => $sample_id,
                    -or => [
                        'pept_response.pept_id' => $neg_id,
                        'pept_response.pept_id' => $pha_id,
                        'pept_response.pept_id' => $cef_id,
                    ]
                ],
            },
            {
                join => { 'pept_response' => [qw/pept_response_corravg experiment/] },
                prefetch => { 'pept_response' => [qw/pept_response_corravg experiment peptide sample/] },
                order_by => [qw/pept_response.pept_id/]
            }
        );

        my $rs = ();
        foreach my $reading_rs (@reading_rs) {
            my $exp_date = $reading_rs->pept_response->experiment->exp_date;
            my $pept_id = $reading_rs->pept_response->pept_id;
            my $peptide = $reading_rs->pept_response->peptide->name;

            $rs->{$pept_id}->{exp_date} = $reading_rs->pept_response->experiment->exp_date if (!defined $rs->{$pept_id}->{exp_date});
            $rs->{$pept_id}->{peptide} = $reading_rs->pept_response->peptide->name if (!defined $rs->{$pept_id}->{peptide});
            $rs->{$pept_id}->{sample_patient} = $reading_rs->pept_response->sample->patient if (!defined $rs->{$pept_id}->{sample_patient});
            $rs->{$pept_id}->{sample_date} = $reading_rs->pept_response->sample->sample_date if (!defined $rs->{$pept_id}->{sample_date});
            $rs->{$pept_id}->{sample_tissue} = $reading_rs->pept_response->sample->tissue if (!defined $rs->{$pept_id}->{sample_tissue});
            $rs->{$pept_id}->{cell_num} = $reading_rs->pept_response->cell_num if (!defined $rs->{$pept_id}->{cell_num});
            $rs->{$pept_id}->{avg} = $reading_rs->pept_response->pept_response_corravg->avg if (!defined $rs->{$pept_id}->{avg});
            $rs->{$pept_id}->{corr_avg} = $reading_rs->pept_response->pept_response_corravg->corr_avg if (!defined $rs->{$pept_id}->{corr_avg});

            if (!defined $rs->{$pept_id}->{value}) {
                $rs->{$pept_id}->{value} = ();
            }
            push @{$rs->{$pept_id}->{value}}, $reading_rs->value;
        }

        my $neg_se = "";
        foreach my $pept_id (sort{$a<=>$b} keys %$rs) {
            my $stdev = my $cv = my $se = my $corr_se = my $se_per = "";
            my $sfc = int ($rs->{$pept_id}->{corr_avg} * 1000000 / $rs->{$pept_id}->{cell_num} * 10 + 0.5) / 10;
            if (scalar @{$rs->{$pept_id}->{value}} > 1) {
                $stdev = get_stdev($rs->{$pept_id}->{value}, $rs->{$pept_id}->{avg});
                $cv = get_cv($stdev, $rs->{$pept_id}->{avg});
                $se = int ($stdev / sqrt(2) * 10 + 0.5) / 10;

                if ($pept_id == 1) {
                    $neg_se = $se;
                }else {
                    if ($neg_se ne "") {
                        $corr_se = int (sqrt($se*$se + $neg_se*$neg_se) * 10 + 0.5) / 10;
                        $se_per = int (($corr_se * sqrt(1000000 / $rs->{$pept_id}->{cell_num})) * 10 + 0.5) / 10;
                    }
                }
            }

            my $single_reading = {
                exp_date => $rs->{$pept_id}->{exp_date},
                pool => $rs->{$pept_id}->{peptide},
                sample_patient => $rs->{$pept_id}->{sample_patient},
                sample_date => $rs->{$pept_id}->{sample_date},
                sample_tissue => $rs->{$pept_id}->{sample_tissue},
                cell_num => $rs->{$pept_id}->{cell_num},
                avg => int ($rs->{$pept_id}->{avg} * 10 + 0.5) / 10,
                corr_avg => int ($rs->{$pept_id}->{corr_avg} * 10 + 0.5) / 10,
                stdev => $stdev,
                cv => $cv,
                se => $se,
                corr_se => $corr_se,
                se_per => $se_per,
                sfc => $sfc,
                value => join(", ", @{$rs->{$pept_id}->{value}})
            };
            push @readings, $single_reading;
        }

        # get pool elispot data for paticular pool_id, exp_id and sample_id
        my @pool_reading_rs = $schema->resultset('reading')->search(
            {
#                -and => [
#                    'pool_response.pool_id' => $pool_id,
#                    'pool_response.exp_id' => $exp_id,
#                    'pool_response.sample_id' => $sample_id,
#                ]
                'me.measure_id' => $measure_id
            },
            {
                join => { 'pool_response' => [qw/pool_response_corravg experiment sample/] },
                prefetch => { 'pool_response' => [qw/pool_response_corravg experiment pool sample/] },
                order_by => [qw/pool_response.exp_id pool_response.sample_id/]
            }
        );

        my $pool_resp_rs = ();
        foreach my $pool_reading_rs (@pool_reading_rs) {
            my $exp_date = $pool_reading_rs->pool_response->experiment->exp_date;
            my $pool = $pool_reading_rs->pool_response->pool->name;
#            warn "date: $exp_date, pool: $pool\n";

            $pool_resp_rs->{exp_date} = $pool_reading_rs->pool_response->experiment->exp_date if (!defined $pool_resp_rs->{exp_date});
            $pool_resp_rs->{pool} = $pool_reading_rs->pool_response->pool->name if (!defined $pool_resp_rs->{peptide});
            $pool_resp_rs->{sample_patient} = $pool_reading_rs->pool_response->sample->patient if (!defined $pool_resp_rs->{sample_patient});
            $pool_resp_rs->{sample_date} = $pool_reading_rs->pool_response->sample->sample_date if (!defined $pool_resp_rs->{sample_date});
            $pool_resp_rs->{sample_tissue} = $pool_reading_rs->pool_response->sample->tissue if (!defined $pool_resp_rs->{sample_tissue});
            $pool_resp_rs->{cell_num} = $pool_reading_rs->pool_response->cell_num if (!defined $pool_resp_rs->{cell_num});
            $pool_resp_rs->{matrix_index} = $pool_reading_rs->pool_response->matrix_index if (!defined $pool_resp_rs->{matrix_index});
            $pool_resp_rs->{avg} = $pool_reading_rs->pool_response->pool_response_corravg->avg if (!defined $pool_resp_rs->{avg});
            $pool_resp_rs->{corr_avg} = $pool_reading_rs->pool_response->pool_response_corravg->corr_avg if (!defined $pool_resp_rs->{corr_avg});
#            warn "index: $pool_resp_rs->{matrix_index}, cells: $pool_resp_rs->{cell_num}, corravg: $pool_resp_rs->{corr_avg}\n";
#            warn "index length: ", length($pool_resp_rs->{matrix_index}), "\n";
            $pool_resp_rs->{matrix_index} = "" if ($pool_resp_rs->{matrix_index} eq "  ");    # don't know why matrix_index="  " if not input matrix_index
            if (!defined $pool_resp_rs->{value}) {
                $pool_resp_rs->{value} = ();
            }
            push @{$pool_resp_rs->{value}}, $pool_reading_rs->value;
        }

        my $stdev = my $cv = my $se = my $corr_se = my $se_per = "";
        my $sfc = int ($pool_resp_rs->{corr_avg} * 1000000 / $pool_resp_rs->{cell_num} * 10 + 0.5) / 10;
        if (scalar @{$pool_resp_rs->{value}} > 1) {
            $stdev = get_stdev($pool_resp_rs->{value}, $pool_resp_rs->{avg});
            $cv = get_cv($stdev, $pool_resp_rs->{avg});
            $se = int ($stdev / sqrt(2) * 10 + 0.5) / 10;

            if ($neg_se ne "") {
                $corr_se = int (sqrt($se*$se + $neg_se*$neg_se) * 10 + 0.5) / 10;
                $se_per = int (($corr_se * sqrt(1000000 / $pool_resp_rs->{cell_num})) * 10 + 0.5) / 10;
            }
        }

        my $single_reading = {
            exp_id => $exp_id,
            exp_date => $pool_resp_rs->{exp_date},
            pool => $pool_resp_rs->{pool},
            sample_id => $sample_id,
            sample_patient => $pool_resp_rs->{sample_patient},
            sample_date => $pool_resp_rs->{sample_date},
            sample_tissue => $pool_resp_rs->{sample_tissue},
            cell_num => $pool_resp_rs->{cell_num},
            matrix_index => $pool_resp_rs->{matrix_index},
            avg => int ($pool_resp_rs->{avg} * 10 + 0.5) / 10,
            corr_avg => int ($pool_resp_rs->{corr_avg} * 10 + 0.5) / 10,
            stdev => $stdev,
            cv => $cv,
            se => $se,
            corr_se => $corr_se,
            se_per => $se_per,
            sfc => $sfc,
            value => join(", ", @{$pool_resp_rs->{value}})
        };
        push @readings, $single_reading;

        push @retrs, \@readings;
    }
    return \@retrs;
}


sub get_titration {
    my ($c, $schema) = @_;

    my $pept_id = $c->req->param('pept_id');
    my $patient_id = $c->req->param('patient_id');
    # get all exp_id and sample_id for the selected peptide
    my @measure_rs = $schema->resultset('titration_corravg')->search(
        {
            'me.pept_id' => $pept_id,
            'sample.patient_id' => $patient_id
        },
        {
            select => [qw/me.pept_id me.exp_id me.sample_id/],
            join => [qw/sample/],
            group_by => [qw/me.pept_id me.exp_id me.sample_id/]
        }
    );

    my @retrs;
    foreach my $measure_rs (@measure_rs) {    # go through each distinct exp_id and sample_id
        my @readings; 
        my $exp_id = $measure_rs->exp_id;
        my $sample_id = $measure_rs->sample_id;
#        warn "pept_id: $pept_id, exp_id: $exp_id, sample_id: $sample_id\n";

        # get negative and positive control sfc for paticular exp_id and sample_id
        my @reading_rs = $schema->resultset('reading')->search(
            {
                -and => [
                    'pept_response.exp_id' => $exp_id,
                    'pept_response.sample_id' => $sample_id,
                    -or => [
                        'pept_response.pept_id' => $neg_id,
                        'pept_response.pept_id' => $pha_id,
                        'pept_response.pept_id' => $cef_id,
                    ]
                ],
            },
            {
                join => { 'pept_response' => [qw/pept_response_corravg experiment/] },
                prefetch => { 'pept_response' => [qw/pept_response_corravg experiment peptide sample/] },
                order_by => [qw/pept_response.pept_id/]
            }
        );

        my $rs = ();
        foreach my $reading_rs (@reading_rs) {
            my $exp_date = $reading_rs->pept_response->experiment->exp_date;
            my $pept_id = $reading_rs->pept_response->pept_id;
            my $peptide = $reading_rs->pept_response->peptide->name;

            $rs->{$pept_id}->{exp_date} = $reading_rs->pept_response->experiment->exp_date if (!defined $rs->{$pept_id}->{exp_date});
            $rs->{$pept_id}->{peptide} = $reading_rs->pept_response->peptide->name if (!defined $rs->{$pept_id}->{peptide});
            $rs->{$pept_id}->{sample_patient} = $reading_rs->pept_response->sample->patient if (!defined $rs->{$pept_id}->{sample_patient});
            $rs->{$pept_id}->{sample_date} = $reading_rs->pept_response->sample->sample_date if (!defined $rs->{$pept_id}->{sample_date});
            $rs->{$pept_id}->{sample_tissue} = $reading_rs->pept_response->sample->tissue if (!defined $rs->{$pept_id}->{sample_tissue});
            $rs->{$pept_id}->{cell_num} = $reading_rs->pept_response->cell_num if (!defined $rs->{$pept_id}->{cell_num});
            $rs->{$pept_id}->{avg} = $reading_rs->pept_response->pept_response_corravg->avg if (!defined $rs->{$pept_id}->{avg});
            $rs->{$pept_id}->{corr_avg} = $reading_rs->pept_response->pept_response_corravg->corr_avg if (!defined $rs->{$pept_id}->{corr_avg});

            if (!defined $rs->{$pept_id}->{value}) {
                $rs->{$pept_id}->{value} = ();
            }
            push @{$rs->{$pept_id}->{value}}, $reading_rs->value;
        }

        my $neg_se = "";
        foreach my $pept_id (sort{$a<=>$b} keys %$rs) {
            my $stdev = my $cv = my $se = my $corr_se = my $se_per = "";
            my $sfc = int ($rs->{$pept_id}->{corr_avg} * 1000000 / $rs->{$pept_id}->{cell_num} * 10 + 0.5) / 10;
            if (scalar @{$rs->{$pept_id}->{value}} > 1) {
                $stdev = get_stdev($rs->{$pept_id}->{value}, $rs->{$pept_id}->{avg});
                $cv = get_cv($stdev, $rs->{$pept_id}->{avg});
                $se = int ($stdev / sqrt(2) * 10 + 0.5) / 10;

                if ($pept_id == 1) {
                    $neg_se = $se;
                }else {
                    if ($neg_se ne "") {
                        $corr_se = int (sqrt($se*$se + $neg_se*$neg_se) * 10 + 0.5) / 10;
                        $se_per = int (($corr_se * sqrt(1000000 / $rs->{$pept_id}->{cell_num})) * 10 + 0.5) / 10;
                    }
                }
            }

            my $single_reading = {
                exp_date => $rs->{$pept_id}->{exp_date},
                peptide => $rs->{$pept_id}->{peptide},
                sample_patient => $rs->{$pept_id}->{sample_patient},
                sample_date => $rs->{$pept_id}->{sample_date},
                sample_tissue => $rs->{$pept_id}->{sample_tissue},
                cell_num => $rs->{$pept_id}->{cell_num},
                avg => int ($rs->{$pept_id}->{avg} * 10 + 0.5) / 10,
                corr_avg => int ($rs->{$pept_id}->{corr_avg} * 10 + 0.5) / 10,
                stdev => $stdev,
                cv => $cv,
                se => $se,
                corr_se => $corr_se,
                se_per => $se_per,
                sfc => $sfc,
                value => join(", ", @{$rs->{$pept_id}->{value}})
            };
            push @readings, $single_reading;
        }

        # get titration data for paticular pept_id, exp_id and sample_id
        my @titration_reading_rs = $schema->resultset('reading')->search(
            {
                -and => [
                    'titration.pept_id' => $pept_id,
                    'titration.exp_id' => $exp_id,
                    'titration.sample_id' => $sample_id,
                ]
            },
            {
                join => { 'titration' => [qw/titration_corravg experiment sample titration_conc/] },
                prefetch => { 'titration' => [qw/titration_corravg experiment peptide sample titration_conc/] },
                order_by => [qw/titration.exp_id titration.sample_id titration.conc_id/]
            }
        );

        my $titration_rs = ();
        foreach my $titration_reading_rs (@titration_reading_rs) {
            my $exp_date = $titration_reading_rs->titration->experiment->exp_date;
            my $conc_id = $titration_reading_rs->titration->conc_id;
            my $peptide = $titration_reading_rs->titration->peptide->name;
#            warn "date: $exp_date, conc_id: $conc_id, pept: $peptide\n";

            $titration_rs->{exp_date} = $titration_reading_rs->titration->experiment->exp_date if (!defined $titration_rs->{exp_date});
            $titration_rs->{peptide} = $titration_reading_rs->titration->peptide->name if (!defined $titration_rs->{peptide});
            $titration_rs->{conc}->{$conc_id} = $titration_reading_rs->titration->titration_conc->conc if (!defined $titration_rs->{conc}->{$conc_id});
            $titration_rs->{sample_patient} = $titration_reading_rs->titration->sample->patient if (!defined $titration_rs->{sample_patient});
            $titration_rs->{sample_date} = $titration_reading_rs->titration->sample->sample_date if (!defined $titration_rs->{sample_date});
            $titration_rs->{sample_tissue} = $titration_reading_rs->titration->sample->tissue if (!defined $titration_rs->{sample_tissue});
            $titration_rs->{ec50} = $titration_reading_rs->titration->ec50 if (!defined $titration_rs->{ec50});
            $titration_rs->{cell_num} = $titration_reading_rs->titration->cell_num if (!defined $titration_rs->{cell_num});
            $titration_rs->{avg}->{$conc_id} = $titration_reading_rs->titration->titration_corravg->avg if (!defined $titration_rs->{avg}->{$conc_id});
            $titration_rs->{corr_avg}->{$conc_id} = $titration_reading_rs->titration->titration_corravg->corr_avg if (!defined $titration_rs->{corr_avg}->{$conc_id});

            if (!defined $titration_rs->{value}->{$conc_id}) {
                $titration_rs->{value}->{$conc_id} = ();
            }
            push @{$titration_rs->{value}->{$conc_id}}, $titration_reading_rs->value;
        }

        foreach my $conc_id (sort{$a<=>$b} keys %{$titration_rs->{conc}}) {
            my $stdev = my $cv = my $se = my $corr_se = my $se_per = "";
            my $sfc = int ($titration_rs->{corr_avg}->{$conc_id} * 1000000 / $titration_rs->{cell_num} * 10 + 0.5) / 10;
            if (scalar @{$titration_rs->{value}->{$conc_id}} > 1) {
                $stdev = get_stdev($titration_rs->{value}->{$conc_id}, $titration_rs->{avg}->{$conc_id});
                $cv = get_cv($stdev, $titration_rs->{avg}->{$conc_id});
                $se = int ($stdev / sqrt(2) * 10 + 0.5) / 10;

                if ($neg_se ne "") {
                    $corr_se = int (sqrt($se*$se + $neg_se*$neg_se) * 10 + 0.5) / 10;
                    $se_per = int (($corr_se * sqrt(1000000 / $titration_rs->{cell_num})) * 10 + 0.5) / 10;
                }
            }

            my $single_reading = {
                exp_date => $titration_rs->{exp_date},
                peptide => $titration_rs->{peptide},
                conc => $titration_rs->{conc}->{$conc_id},
                sample_patient => $titration_rs->{sample_patient},
                sample_date => $titration_rs->{sample_date},
                sample_tissue => $titration_rs->{sample_tissue},
                cell_num => $titration_rs->{cell_num},
                ec50 => $titration_rs->{ec50},
                avg => int ($titration_rs->{avg}->{$conc_id} * 10 + 0.5) / 10,
                corr_avg => int ($titration_rs->{corr_avg}->{$conc_id} * 10 + 0.5) / 10,
                stdev => $stdev,
                cv => $cv,
                se => $se,
                corr_se => $corr_se,
                se_per => $se_per,
                sfc => $sfc,
                value => join(", ", @{$titration_rs->{value}->{$conc_id}})
            };
            push @readings, $single_reading;
        }
        push @retrs, \@readings;
    }
    return \@retrs;
}


sub get_hla_restriction {
    my ($c, $schema) = @_;

    my $pept_id = $c->req->param('pept_id');
    my $patient_id = $c->req->param('patient_id');
    # get all exp_id and sample_id for the selected peptide
    my @measure_rs = $schema->resultset('hla_response_corravg')->search(
        {
            'me.pept_id' => $pept_id,
            'sample.patient_id' => $patient_id
        },
        {
            select => [qw/me.pept_id me.exp_id me.sample_id/],
            join => [qw/sample/],
            group_by => [qw/me.pept_id me.exp_id me.sample_id/]
        }
    );

    my @retrs;
    foreach my $measure_rs (@measure_rs) {    # go through each distinct exp_id and sample_id
        my @readings; 
        my $exp_id = $measure_rs->exp_id;
        my $sample_id = $measure_rs->sample_id;
#        warn "pept_id: $pept_id, exp_id: $exp_id, sample_id: $sample_id\n";

        # get negative and positive control sfc for paticular exp_id and sample_id
        my @reading_rs = $schema->resultset('reading')->search(
            {
                -and => [
                    'pept_response.exp_id' => $exp_id,
                    'pept_response.sample_id' => $sample_id,
                    -or => [
                        'pept_response.pept_id' => $neg_id,
                        'pept_response.pept_id' => $pha_id,
                        'pept_response.pept_id' => $cef_id,
                    ]
                ],
            },
            {
                join => { 'pept_response' => [qw/pept_response_corravg experiment/] },
                prefetch => { 'pept_response' => [qw/pept_response_corravg experiment peptide sample/] },
                order_by => [qw/pept_response.pept_id/]
            }
        );

        my $rs = ();
        foreach my $reading_rs (@reading_rs) {
            my $exp_date = $reading_rs->pept_response->experiment->exp_date;
            my $pept_id = $reading_rs->pept_response->pept_id;
            my $peptide = $reading_rs->pept_response->peptide->name;
#            warn "neg: $exp_date, $pept_id, $peptide\n";
            $rs->{$pept_id}->{exp_date} = $reading_rs->pept_response->experiment->exp_date if (!defined $rs->{$pept_id}->{exp_date});
            $rs->{$pept_id}->{peptide} = $reading_rs->pept_response->peptide->name if (!defined $rs->{$pept_id}->{peptide});
            $rs->{$pept_id}->{sample_patient} = $reading_rs->pept_response->sample->patient if (!defined $rs->{$pept_id}->{sample_patient});
            $rs->{$pept_id}->{sample_date} = $reading_rs->pept_response->sample->sample_date if (!defined $rs->{$pept_id}->{sample_date});
            $rs->{$pept_id}->{sample_tissue} = $reading_rs->pept_response->sample->tissue if (!defined $rs->{$pept_id}->{sample_tissue});
            $rs->{$pept_id}->{cell_num} = $reading_rs->pept_response->cell_num if (!defined $rs->{$pept_id}->{cell_num});
            $rs->{$pept_id}->{avg} = $reading_rs->pept_response->pept_response_corravg->avg if (!defined $rs->{$pept_id}->{avg});
            $rs->{$pept_id}->{corr_avg} = $reading_rs->pept_response->pept_response_corravg->corr_avg if (!defined $rs->{$pept_id}->{corr_avg});

            if (!defined $rs->{$pept_id}->{value}) {
                $rs->{$pept_id}->{value} = ();
            }
            push @{$rs->{$pept_id}->{value}}, $reading_rs->value;
        }

        my $neg_se = "";
        foreach my $pept_id (sort{$a<=>$b} keys %$rs) {

            my $stdev = my $cv = my $se = my $corr_se = my $se_per = "";
            my $sfc = int ($rs->{$pept_id}->{corr_avg} * 1000000 / $rs->{$pept_id}->{cell_num} * 10 + 0.5) / 10;
            if (scalar @{$rs->{$pept_id}->{value}} > 1) {
                $stdev = get_stdev($rs->{$pept_id}->{value}, $rs->{$pept_id}->{avg});
                $cv = get_cv($stdev, $rs->{$pept_id}->{avg});
                $se = int ($stdev / sqrt(2) * 10 + 0.5) / 10;

                if ($pept_id == 1) {
                    $neg_se = $se;
                }else {
                    if ($neg_se ne "") {
                        $corr_se = int (sqrt($se*$se + $neg_se*$neg_se) * 10 + 0.5) / 10;
                        $se_per = int (($corr_se * sqrt(1000000 / $rs->{$pept_id}->{cell_num})) * 10 + 0.5) / 10;
                    }
                }
            }

            my $single_reading = {
                exp_date => $rs->{$pept_id}->{exp_date},
                peptide => $rs->{$pept_id}->{peptide},
                sample_patient => $rs->{$pept_id}->{sample_patient},
                sample_date => $rs->{$pept_id}->{sample_date},
                sample_tissue => $rs->{$pept_id}->{sample_tissue},
                cell_num => $rs->{$pept_id}->{cell_num},
                avg => int ($rs->{$pept_id}->{avg} * 10 + 0.5) / 10,
                corr_avg => int ($rs->{$pept_id}->{corr_avg} * 10 + 0.5) / 10,
                stdev => $stdev,
                cv => $cv,
                se => $se,
                corr_se => $corr_se,
                se_per => $se_per,
                sfc => $sfc,
                value => join(", ", @{$rs->{$pept_id}->{value}})
            };
            push @readings, $single_reading;
        }

        # get hla response data for exp_id and sample_id
        my @hla_response_reading_rs = $schema->resultset('reading')->search(
            {
                -and => [
                    'hla_response.exp_id' => $exp_id,
                    'hla_response.sample_id' => $sample_id,
                    -or => [
                        'hla_response.pept_id' => $neg_id,
                        'hla_response.pept_id' => $pept_id,
                    ]
                ]
            },
            {
                join => { 'hla_response' => [qw/hla_response_corravg experiment sample blcl/] },
                prefetch => { 'hla_response' => [qw/hla_response_corravg experiment sample blcl/] },
                order_by => [qw/hla_response.exp_id hla_response.sample_id hla_response.blcl_id/],
            }
        );

        my $hla_response_rs = ();
        my (@pept_ids, %pept_id_status);
        foreach my $hla_response_reading_rs (@hla_response_reading_rs) {
            my $exp_date = $hla_response_reading_rs->hla_response->experiment->exp_date;
            my $blcl_id = $hla_response_reading_rs->hla_response->blcl_id;
            my $pept_id = $hla_response_reading_rs->hla_response->pept_id;
            my $peptide = $hla_response_reading_rs->hla_response->peptide->name;

            $hla_response_rs->{exp_date} = $hla_response_reading_rs->hla_response->experiment->exp_date if (!defined $hla_response_rs->{exp_date});
            $hla_response_rs->{peptide}->{$pept_id} = $hla_response_reading_rs->hla_response->peptide->name if (!defined $hla_response_rs->{peptide}->{$pept_id});
            unless ($pept_id == $neg_id) {
                $hla_response_rs->{blcl}->{$blcl_id} = $hla_response_reading_rs->hla_response->blcl->name if (!defined $hla_response_rs->{$pept_id}->{blcl}->{$blcl_id});
            }
#            $hla_response_rs->{$pept_id}->{blcl}->{$blcl_id} = $hla_response_reading_rs->hla_response->blcl->name if (!defined $hla_response_rs->{$pept_id}->{blcl}->{$blcl_id});
            $hla_response_rs->{sample_patient} = $hla_response_reading_rs->hla_response->sample->patient if (!defined $hla_response_rs->{sample_patient});
            $hla_response_rs->{sample_date} = $hla_response_reading_rs->hla_response->sample->sample_date if (!defined $hla_response_rs->{sample_date});
            $hla_response_rs->{sample_tissue} = $hla_response_reading_rs->hla_response->sample->tissue if (!defined $hla_response_rs->{sample_tissue});
            $hla_response_rs->{cell_num} = $hla_response_reading_rs->hla_response->cell_num if (!defined $hla_response_rs->{cell_num});
            $hla_response_rs->{$pept_id}->{avg}->{$blcl_id} = $hla_response_reading_rs->hla_response->hla_response_corravg->avg if (!defined $hla_response_rs->{$pept_id}->{avg}->{$blcl_id});
            $hla_response_rs->{$pept_id}->{corr_avg}->{$blcl_id} = $hla_response_reading_rs->hla_response->hla_response_corravg->corr_avg if (!defined $hla_response_rs->{$pept_id}->{corr_avg}->{$blcl_id});

            if (!@pept_ids || !$pept_id_status{$pept_id}) {
                push @pept_ids, $pept_id;
                $pept_id_status{$pept_id} = 1;
            }

            if (!defined $hla_response_rs->{$pept_id}->{value}->{$blcl_id}) {
                $hla_response_rs->{$pept_id}->{value}->{$blcl_id} = ();
            }
            push @{$hla_response_rs->{$pept_id}->{value}->{$blcl_id}}, $hla_response_reading_rs->value;
        }

        foreach my $pept_id (sort @pept_ids) {
#            foreach my $blcl_id (sort{$a<=>$b} keys %{$hla_response_rs->{$pept_id}->{blcl}}) {
            foreach my $blcl_id (sort{$a<=>$b} keys %{$hla_response_rs->{blcl}}) {
                my $stdev = my $cv = my $se = my $corr_se = my $se_per = my $ratio = "";
                my $sfc = int ($hla_response_rs->{$pept_id}->{corr_avg}->{$blcl_id} * 1000000 / $hla_response_rs->{cell_num} * 10 + 0.5) / 10;
                if (scalar @{$hla_response_rs->{$pept_id}->{value}->{$blcl_id}} > 1) {
                    $stdev = get_stdev($hla_response_rs->{$pept_id}->{value}->{$blcl_id}, $hla_response_rs->{$pept_id}->{avg}->{$blcl_id});
                    $cv = get_cv($stdev, $hla_response_rs->{$pept_id}->{avg}->{$blcl_id});
                    $se = int ($stdev / sqrt(2) * 10 + 0.5) / 10;

                    if ($neg_se ne "") {
                        $corr_se = int (sqrt($se*$se + $neg_se*$neg_se) * 10 + 0.5) / 10;
                        $se_per = int (($corr_se * sqrt(1000000 / $hla_response_rs->{cell_num})) * 10 + 0.5) / 10;
                    }
                }

                unless ($pept_id == 1) {
                    my $neg_corravg = $hla_response_rs->{1}->{corr_avg}->{$blcl_id};
                    if ($neg_corravg == 0) {
                        if ($hla_response_rs->{$pept_id}->{corr_avg}->{$blcl_id} > 0) {
                            $ratio = "> 2";
                        }else {
                            $ratio = "< 0";
                        }
                    }else {
                        $ratio = int ($hla_response_rs->{$pept_id}->{corr_avg}->{$blcl_id} / $neg_corravg * 10 + 0.5) / 10;
                    }
                }

                my $single_reading = {
                    exp_date => $hla_response_rs->{exp_date},
                    peptide => $hla_response_rs->{peptide}->{$pept_id},
#                    blcl => $hla_response_rs->{$pept_id}->{blcl}->{$blcl_id},
                    blcl => $hla_response_rs->{blcl}->{$blcl_id},
                    sample_patient => $hla_response_rs->{sample_patient},
                    sample_date => $hla_response_rs->{sample_date},
                    sample_tissue => $hla_response_rs->{sample_tissue},
                    cell_num => $hla_response_rs->{cell_num},
                    ratio => $ratio,
                    avg => int ($hla_response_rs->{$pept_id}->{avg}->{$blcl_id} * 10 + 0.5) / 10,
                    corr_avg => int ($hla_response_rs->{$pept_id}->{corr_avg}->{$blcl_id} * 10 + 0.5) / 10,
                    stdev => $stdev,
                    cv => $cv,
                    se => $se,
                    corr_se => $corr_se,
                    se_per => $se_per,
                    sfc => $sfc,
                    value => join(", ", @{$hla_response_rs->{$pept_id}->{value}->{$blcl_id}})
                };
                push @readings, $single_reading;
            }
        }
        push @retrs, \@readings;
    }
    return \@retrs;
}


sub get_mutant {
    my ($c, $schema) = @_;

    my $pept_id = $c->req->param('pept_id');
    my $patient_id = $c->req->param('patient_id');

    my @rs = $schema->resultset('epitope')->search(
        {
            'me.pept_id' => $pept_id,
            'epitope_mutant.patient_id' => $patient_id,
        },
        {
            select => [ 'mutant.pept_id',
                        'peptide.name',
                        'peptide.sequence',
                        'peptide.position_hxb2_start',
                        'peptide.position_hxb2_end',
                        'epitope_mutant.patient_id', 
                        'epitope_mutant.note',
                    ],
            as => [qw/pept_id name seq hxb2_start hxb2_end patient_id note/],
            join => {'epitope_mutant' => [{'mutant' => ['peptide']}]},

            group_by => [qw/mutant.pept_id peptide.name peptide.sequence peptide.position_hxb2_start peptide.position_hxb2_end 
                        epitope_mutant.patient_id epitope_mutant.note/],
        }
    );

    my @retrs;
    foreach my $rs (@rs) {
        my $pept_id = $rs->get_column('pept_id');
        my $peptide = $rs->get_column('name');
        my $sequence = $rs->get_column('seq');
        my $hxb2_start = $rs->get_column('hxb2_start');
        my $hxb2_end = $rs->get_column('hxb2_end');
        my $patient_id = $rs->get_column('patient_id');
        my $note = $rs->get_column('note');

        # get maximum value of sfc from pept_response_corravg
        my $max_rs = $schema->resultset('pept_response_corravg')->search(
            {
                'me.pept_id' => $pept_id,
                'sample.patient_id' => $patient_id,
            },
            {
                select => [    'sample.patient', 
                            {MAX => 'me.corr_avg'},
                        ],
                as => [qw/patient max/],
                join => ['sample'],

                group_by => [qw/sample.patient/],
            }
        );
        my $max_corravg = "";
        my $patient;
        if (my $max = $max_rs->next) {
            $patient = $max->get_column('patient');
            if (defined $max->get_column('max')) {
                $max_corravg = int ($max->get_column('max') * 100 + 0.5) / 100;
            }
        }

        # get minimum value of ec50 from titration if there exist
        my $min_rs = $schema->resultset('titration')->search(
            {
                'me.pept_id' => $pept_id,
                'sample.patient_id' => $patient_id,
            },
            {
                select => [{MIN => 'me.ec50'}],
                as => [qw/min/],
                join => ['sample'],
            }
        );
        my $min_ec50 = "";
        if (my $min = $min_rs->next) {
            if ($min->get_column('min')) {
                if ($min->get_column('min') eq "undef") {
                    $min_ec50 = "nudef";
                }else {
                    $min_ec50 = int ($min->get_column('min') * 10000 + 0.5) / 10000;
                }
            }
        }

        # get result of hla restriction if there exist
        my $hr_rs = $schema->resultset('hla_response')->search(
            {
                'me.pept_id' => $pept_id,
                'sample.patient_id' => $patient_id,
            },
            {
                join => ['sample'],
            }
        );

        my $hr_result = "";
        if ($hr_rs->next) {
            $hr_result = "Result";
        }
#        warn "id: $pept_id, patient: $patient, note: $note, max: $max_corravg, min: $min_ec50, count: $hr_result\n";
#        next;

        # get hla types for the peptide in any
        my @hla_rs = $schema->resultset('hla_pept')->search(
            {'pept_id' => $pept_id},
            {
                join => ['hla'],
                prefetch => ['hla']
            }
        );
        my $hla_type = "";
        foreach my $hla_rs (@hla_rs) {
            if ($hla_type) {
                $hla_type .= ", ";
            }
            $hla_type .= $hla_rs->hla->type;
        }

        my $retrs = {
            pept_id => $pept_id,
            peptide => $peptide,
            sequence => $sequence,
            position_hxb2_start => $hxb2_start,
            position_hxb2_end => $hxb2_end,
            patient => $patient,
            patient_id => $patient_id,
            max_corravg => $max_corravg,
            min_ec50 => $min_ec50,
            hla => $hla_type,
            hla_response => $hr_result,
            note => $note
        };
        push @retrs, $retrs;
    }
    return \@retrs;
}


sub get_stdev {
    my ($valuesRef, $avg) = @_;
    my $stdev = "";
    my $readings = scalar @$valuesRef;
    if ($readings > 1) {
        my $sum = 0;
        foreach my $value (@$valuesRef) {
            $sum += ($value - $avg) * ($value - $avg);
        }
        $stdev = int (sqrt ($sum / ($readings - 1)) * 10 + 0.5) / 10;
    }
    return $stdev;
}

sub get_cv {
    my ($stdev, $avg) = @_;
    my $cv = "";
    unless ($avg == 0) {
        $cv = int (100 * $stdev / $avg * 10 + 0.5) / 10;
    }
    return $cv;
}

1;

__END__


=head1 AUTHOR

Wenjie E<lt>dengw@u.washington.eduE<gt>

=head1 COPYRIGHT AND LICENSE

This code was developed under funding from WA State ATI.  

=cut 

