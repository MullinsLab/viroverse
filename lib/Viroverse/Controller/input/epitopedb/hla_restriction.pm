
package Viroverse::Controller::input::epitopedb::hla_restriction;
use base 'Viroverse::Controller';

use strict;
use warnings;

use Viroverse::epitopedb::input;
use Text::ParseWords;
use Data::Dumper;
use Carp;

=head1 NAME

Viroverse::Controller::input::epitopedb - Holds Catalyst actions under /input/epitopedb to add with ELISpot data to VV

=head1 SYNOPSIS

See L<Viroverse>

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=item begin
=cut

my $schema = EpitopeDB->connect(Viroverse::Config->conf->{dsn}, Viroverse::Config->conf->{read_write_user},Viroverse::Config->conf->{read_write_pw});

sub section {
    return 'input';
}

sub subsection {
    return 'epitope';
}

sub index : Private {
    my ($self, $context) = @_;
    $context->stash->{years} = Viroverse::epitopedb::input::list_years();
    $context->stash->{months} = Viroverse::epitopedb::input::list_months();
    $context->stash->{days} = Viroverse::epitopedb::input::list_days();
    $context->stash->{blcls} = Viroverse::epitopedb::input::list_blcls($schema);
    $context->stash->{hlas} = Viroverse::epitopedb::input::list_hlas($schema);
    $context->stash->{'cohorts'} = $context->model("ViroDB::Cohort")->list_all;
    $context->stash->{template} = 'epitopedb/hla_restriction.tt';
}

sub result : Local {
    my ($self, $c) = @_;

    my $upload = $c->request->upload('inputfile');

    if ($upload) {
        my $records;
        my $i = 0;
        my $validate_flag = 1;
        my $exist = my $update = my $new = my $total = 0;

        my $fh = $upload->fh;
        my @buffer = <$fh>;
        my $lines_ref = Viroverse::epitopedb::input::getFileLines (\@buffer);
        foreach my $line (@$lines_ref) {
            unless ($line =~ /^Exp/i || $line =~ /^\s*$/) {
                my @fields = quotewords ('\t', 0, $line);
                my @cleanFields = Viroverse::epitopedb::input::cleanFields (\@fields);
                my $exp_date = shift @cleanFields;
                my $plate_num = shift @cleanFields;
                my $cohort = shift @cleanFields;
                my $patient = shift @cleanFields;
                my $sample_date = shift @cleanFields;
                my $tissue_type = shift @cleanFields;
                my $pept_name = uc shift @cleanFields;
                my $pept_seq = uc shift @cleanFields;
                my $blcl = shift @cleanFields;
                my $cell_num = shift @cleanFields;
                my $hla = shift @cleanFields;
                my $note = shift @cleanFields;
                my @sfcs;

                foreach my $sfc (@cleanFields) {
                    if ($sfc ne "") {
                        push @sfcs, $sfc;
                    }
                }

                if ($pept_name || $pept_seq) {
                    if (!$exp_date || !$plate_num || !$cohort || !$patient || !$sample_date || !$tissue_type || !$cell_num || !@sfcs || !$blcl) {
                        $c->stash->{status} = "missing fields 1";
                        $validate_flag = 0;
                        last;
                    }
                }else {
                    $c->stash->{status} = "missing fields 2";
                    $validate_flag = 0;
                    last;
                }

                if ($exp_date !~ /^\d{4}-\d{2}-\d{2}$/) {
                    $c->stash->{status} = "Experiment date $exp_date is not in correct format";
                    $validate_flag = 0;
                    last;
                }elsif ($sample_date !~ /^\d{4}-\d{2}-\d{2}$/) {
                    $c->stash->{status} = "Sample date $sample_date is not in correct format";
                    $validate_flag = 0;
                    last;
                }elsif ($pept_seq && $pept_seq !~ /^[A-Z]+$/) {
                    $c->stash->{status} = "Peptide sequence $pept_seq is not in correct format";
                    $validate_flag = 0;
                    last;
                }elsif ($cell_num !~ /^\d+$/) {
                    $c->stash->{status} = "Cell number $cell_num is not in correct format";
                    $validate_flag = 0;
                    last;
                }else {
                    foreach my $sfc (@sfcs) {
                        if ($sfc !~ /^\d+$/) {
                            $c->stash->{status} = "Number of spot forming cells $sfc is not in correct format";
                            $validate_flag = 0;
                            last;
                        }
                    }
                }

                my $pept_id = Viroverse::epitopedb::input::get_pept_id($schema, $pept_name, $pept_seq);
                if (!$pept_id) {
                    $c->stash->{status} = "Couldn't find peptide $pept_name $pept_seq";
                    $validate_flag = 0;
                    last;
                }

                my $cohort_id = Viroverse::epitopedb::input::get_cohort_id($schema, $cohort);
                if (!$cohort_id) {
                    $c->stash->{status} = "Couldn't find cohort $cohort";
                    $validate_flag = 0;
                    last;
                }

                my $tissue_type_id = Viroverse::epitopedb::input::get_tissue_type_id($schema, $tissue_type);
                if (!$tissue_type_id) {
                    $c->stash->{status} = "Couldn't find tissue type $tissue_type";
                    $validate_flag = 0;
                    last;
                }

                my $hla_id = "";
                if ($hla) {
                    $hla_id = Viroverse::epitopedb::input::find_hla_id($schema, $hla);
                    if (!$hla_id) {
                        $c->stash->{status} = "Couldn't find HLA type $hla";
                        $validate_flag = 0;
                        last;
                    }
                }

                my $exp_id = Viroverse::epitopedb::input::get_exp_id($schema, $exp_date, $plate_num, $note);

                my $patient_id = Viroverse::epitopedb::input::get_patient_id($schema, $cohort_id, $patient);

                my $blcl_id = Viroverse::epitopedb::input::find_or_create_blcl_id($schema, $blcl);

                my $visit_id = Viroverse::epitopedb::input::get_visit_id($schema, $patient_id, $sample_date);

                my $sample_id = Viroverse::epitopedb::input::get_sample_id($schema, $visit_id, $tissue_type_id);

                $records->{$i} = ();
                push @{$records->{$i}}, $exp_id, $pept_id, $sample_id, $blcl_id, $cell_num, $hla_id, @sfcs;
                $i++;
            }
        }
        if ($validate_flag) {
            foreach my $row (sort {$a <=> $b} keys %$records) {
                my @fields = @{$records->{$row}};
                my $exp_id = shift @fields;
                my $pept_id = shift @fields;
                my $sample_id = shift @fields;
                my $blcl_id = shift @fields;
                my $cell_num = shift @fields;
                my $hla_id = shift @fields;
                my @sfcs = @fields;

                if ($hla_id) {
                    Viroverse::epitopedb::input::add_hla_pept($schema, $pept_id, $hla_id);
                }

                my ($measure_id, $status) = Viroverse::epitopedb::input::get_hla_restriction_measure_id($schema, $exp_id, $sample_id, $cell_num, $pept_id, $blcl_id, \@sfcs);

                if ($status eq "exist") {
                    $exist++;
                }elsif ($status eq "new") {
                    Viroverse::epitopedb::input::add_readings($schema, $measure_id, \@sfcs);
                    $new++;
                }else {
                    if ($status->{sfc}) {
                        Viroverse::epitopedb::input::update_readings($schema, $measure_id, \@sfcs);
                    }
                    if ($status->{cell}) {
                        Viroverse::epitopedb::input::update_cell_num($schema, "hla_response", $measure_id, $cell_num);
                    }
                    $update++;
                }
                $total++;
            }
            $c->stash->{status} = "Manipulated total $total records:<br>
                                    $exist of them exist in database<br>
                                    $update of them update in database<br>
                                    $new of them input into database<br>";
        }

        $c->stash->{years} = Viroverse::epitopedb::input::list_years();
        $c->stash->{months} = Viroverse::epitopedb::input::list_months();
        $c->stash->{days} = Viroverse::epitopedb::input::list_days();
        $c->stash->{blcls} = Viroverse::epitopedb::input::list_blcls($schema);
        $c->stash->{hlas} = Viroverse::epitopedb::input::list_hlas($schema);
        $c->stash->{'cohorts'} = $c->model("ViroDB::Cohort")->list_all;
        $c->stash->{template} = 'epitopedb/hla_restriction.tt';
    }else {
        my $year = $c->req->param("exp_year");
        my $month = $c->req->param("exp_month");
        my $day = $c->req->param("exp_day");
        my $note = $c->req->param("exp_note");
        my $plate = $c->req->param("plate");
        my $sample_id = $c->req->param("sample_id");
        my $cell_num = $c->req->param("cell_num");
        my $pept_name = uc $c->req->param("pept_name");
        my $pept_seq = uc $c->req->param("pept_seq");
        my $blcl_id = $c->req->param("blcl");
        my @sfcs = $c->req->param("sfc");
        my $hla_id = $c->req->param("hla");
        my $type = "hla_response";

        my $exp_date = $year."-".$month."-".$day;
        my $exp_id = Viroverse::epitopedb::input::get_exp_id($schema, $exp_date, $plate, $note);

        my $pept_id = Viroverse::epitopedb::input::get_pept_id($schema, $pept_name, $pept_seq);

        if (!$pept_id) {
            $c->response->body('Error: unable to resolve peptide, please import the peptide first');
            return;
        }

        if ($hla_id) {
            Viroverse::epitopedb::input::add_hla_pept($schema, $pept_id, $hla_id);
        }

        my ($measure_id, $status) = Viroverse::epitopedb::input::get_hla_restriction_measure_id($schema, $exp_id, $sample_id, $cell_num, $pept_id, $blcl_id, \@sfcs);

        if ($status eq "new") {
            Viroverse::epitopedb::input::add_readings($schema, $measure_id, \@sfcs);
        }

        if ($status ne "new" && $status ne "exist") {
            if ($status->{sfc}) {
                my @readings = Viroverse::epitopedb::input::get_reading($schema, $measure_id);
                my $readings = join (",", @readings) if (@readings);
                my $sfcs = join (",", @sfcs);
                $c->stash->{readings} = $readings;
                $c->stash->{sfcs} = $sfcs;
            }

            if ($status->{cell}) {
                $c->stash->{exist_cell_num} = Viroverse::epitopedb::input::get_cell_num($schema, $measure_id, $type);
                $c->stash->{input_cell_num} = $cell_num;
            }
            $c->stash->{measure_id} = $measure_id;
        }
        $c->stash->{type} = $type;
        $c->stash->{status} = $status;
        $c->stash->{template} = 'epitopedb/epitopedb_input_sidebar.tt';
    }
}



1;
