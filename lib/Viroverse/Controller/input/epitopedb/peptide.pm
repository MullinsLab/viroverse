
package Viroverse::Controller::input::epitopedb::peptide;
use base 'Viroverse::Controller';

use strict;
use warnings;

use Viroverse::epitopedb::input;
use EpitopeDB;
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
    $context->stash->{origins} = Viroverse::epitopedb::input::get_origins($schema);
    $context->stash->{regions} = Viroverse::epitopedb::input::get_regions($schema);
    $context->stash->{template} = 'epitopedb/peptide.tt';
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
            unless ($line =~ /^Peptide/i || $line =~ /^\s*$/) {
                my @fields = quotewords ('\t', 0, $line);
                my @cleanFields = Viroverse::epitopedb::input::cleanFields (\@fields);
                my $pept_name = uc $cleanFields[0];
                my $pept_seq = uc $cleanFields[1];
                my $gene = $cleanFields[2];
                my $hxb2_start = $cleanFields[3];
                my $hxb2_end = $cleanFields[4];
                my $origin = $cleanFields[5];
                unless (defined $pept_name && defined $pept_seq && defined $gene && defined $hxb2_start && defined $hxb2_end) {
#                if (!$pept_name || !$pept_seq || !$gene || !$hxb2_start || !$hxb2_end) {
                    $c->stash->{status} = "missing fields";
                    $validate_flag = 0;
                    last;
                }
                if ($pept_seq !~ /^[A-Z]+$/) {
                    $c->stash->{status} = "Peptide sequence $pept_seq is not in correct format";
                    $validate_flag = 0;
                    last;
                }elsif ($gene !~ /^[a-zA-Z]+$/) {
                    $c->stash->{status} = "Gene region $gene is not in correct format";
                    $validate_flag = 0;
                    last;
                }elsif ($hxb2_start !~ /^\d+$/ || $hxb2_end !~ /^\d+$/) {
                    $c->stash->{status} = "HXB2 location must be a number";
                    $validate_flag = 0;
                    last;
                }

                my $gene_id = Viroverse::epitopedb::input::get_gene_id($schema, $gene);
                unless ($gene_id) {
                    $c->stash->{status} = "Couldn't find gene $gene";
                    $validate_flag = 0;
                    last;
                }
                my $origin_id = 1;
                if ($origin) {
                    $origin_id = Viroverse::epitopedb::input::get_origin_id($schema, $origin);
                }
                $records->{$i} = ();
                push @{$records->{$i}}, $pept_name, $pept_seq, $gene_id, $hxb2_start, $hxb2_end, $origin_id;
                $i++;
            }
        }

        if ($validate_flag) {
            foreach my $row (sort {$a <=> $b} keys %$records) {
                my @fields = @{$records->{$row}};
                my $pept_name = $fields[0];
                my $pept_seq = $fields[1];
                my $gene_id = $fields[2];
                my $hxb2_start = $fields[3];
                my $hxb2_end = $fields[4];
                my $origin_id = $fields[5];
                my ($pept_id, $status) = Viroverse::epitopedb::input::get_peptide_pept_id($schema, $pept_name, $pept_seq, $origin_id, $gene_id, $hxb2_start, $hxb2_end);

                if ($status eq "exist") {
                    $exist++;
                }elsif ($status eq "new") {
                    $new++;
                }else {
                    if ($status->{name}) {
                        Viroverse::epitopedb::input::update_peptide($schema, $pept_id, $pept_name, "name");
                    }
                    if ($status->{seq}) {
                        Viroverse::epitopedb::input::update_peptide($schema, $pept_id, $pept_seq, "sequence");
                    }
                    if ($status->{origin}) {
                        Viroverse::epitopedb::input::update_peptide($schema, $pept_id, $origin_id, "origin_id");
                    }
                    if ($status->{region}) {
                        Viroverse::epitopedb::input::update_peptide($schema, $pept_id, $gene_id, "gene_id");
                    }
                    if ($status->{hxb2_start}) {
                        Viroverse::epitopedb::input::update_peptide($schema, $pept_id, $hxb2_start, "position_hxb2_start");
                    }
                    if ($status->{hxb2_end}) {
                        Viroverse::epitopedb::input::update_peptide($schema, $pept_id, $hxb2_end, "position_hxb2_end");
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
        $c->stash->{origins} = Viroverse::epitopedb::input::get_origins($schema);
        $c->stash->{regions} = Viroverse::epitopedb::input::get_regions($schema);
        $c->stash->{type} = "peptide";
        $c->stash->{template} = 'epitopedb/peptide.tt';
    }else {
        my $pept_name = uc $c->req->param("pept_name");
        my $pept_seq = uc $c->req->param("pept_seq");
        my $origin_id = $c->req->param("origin");
        my $gene_id = $c->req->param("region");
        my $hxb2_start = $c->req->param("hxb2_start");
        my $hxb2_end = $c->req->param("hxb2_end");

        my ($pept_id, $status);

        ($pept_id, $status) = Viroverse::epitopedb::input::get_peptide_pept_id($schema, $pept_name, $pept_seq, $origin_id, $gene_id, $hxb2_start, $hxb2_end);

        if ($status ne "new" && $status ne "exist") {
            $c->stash->{pept_id} = $pept_id;
            if ($status->{name}) {
                $c->stash->{exist_name} = Viroverse::epitopedb::input::find_pept_attrs_by_pept_id($schema, $pept_id, "name");
                $c->stash->{input_name} = $pept_name;
            }
            if ($status->{seq}) {
                $c->stash->{exist_seq} = Viroverse::epitopedb::input::find_pept_attrs_by_pept_id($schema, $pept_id, "sequence");
                $c->stash->{input_seq} = $pept_seq;
            }
            if ($status->{origin}) {
                $c->stash->{exist_origin} = Viroverse::epitopedb::input::get_origin_by_pept_id($schema, $pept_id);
                $c->stash->{input_origin} = Viroverse::epitopedb::input::get_origin_by_origin_id($schema, $origin_id);
            }
            if ($status->{region}) {
                $c->stash->{exist_region} = Viroverse::epitopedb::input::get_gene_by_pept_id($schema, $pept_id);
                $c->stash->{input_region} = Viroverse::epitopedb::input::get_gene_by_gene_id($schema, $gene_id);
            }
            if ($status->{hxb2_start}) {
                $c->stash->{exist_hxb2_start} = Viroverse::epitopedb::input::find_pept_attrs_by_pept_id($schema, $pept_id, "position_hxb2_start");
                $c->stash->{input_hxb2_start} = $hxb2_start;
            }
            if ($status->{hxb2_end}) {
                $c->stash->{exist_hxb2_end} = Viroverse::epitopedb::input::find_pept_attrs_by_pept_id($schema, $pept_id, "position_hxb2_end");
                $c->stash->{input_hxb2_end} = $hxb2_end;
            }
        }
        $c->stash->{type} = "peptide";
        $c->stash->{status} = $status;
        $c->stash->{template} = 'epitopedb/epitopedb_input_sidebar.tt';
    }
}



1;
