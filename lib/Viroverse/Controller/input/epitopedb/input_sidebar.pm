
package Viroverse::Controller::input::epitopedb::input_sidebar;
use base 'Viroverse::Controller';

use strict;
use warnings;

use Viroverse::epitopedb::input;

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
    return '';
}


sub update : Local {
    my ($self, $c) = @_;
    my $type = $c->req->param("type");

    if ($type eq "pept_response" || $type eq "titration" || $type eq "hla_response" || $type eq "pool_response") {
        my $measure_id = $c->req->param("measure_id");
        if (my $sfcs = $c->req->param("sfcs")) {
            my @sfcs = split /,/, $sfcs;
            Viroverse::epitopedb::input::update_readings($schema, $measure_id, \@sfcs);
        }
        if (my $input_cell_num = $c->req->param("input_cell_num")) {
            Viroverse::epitopedb::input::update_cell_num($schema, $type, $measure_id, $input_cell_num);
        }
        if (my $input_ec50 = $c->req->param("input_ec50")) {
            Viroverse::epitopedb::input::update_ec50($schema, $type, $measure_id, $input_ec50);
        }
    }elsif ($type eq "epitope_result") {
        Viroverse::epitopedb::input::update_epitope($schema, $c);
    }elsif ($type eq "mutant_result") {
        Viroverse::epitopedb::input::update_epitope_mutant($schema, $c);
    }elsif ($type eq "peptide") {
        my $pept_id = $c->req->param("pept_id");
        if (my $input_pept_name = $c->req->param("pept_name")) {
            Viroverse::epitopedb::input::update_peptide($schema, $pept_id, $input_pept_name, "name");
        }
        if (my $input_pept_seq = $c->req->param("pept_seq")) {
            Viroverse::epitopedb::input::update_peptide($schema, $pept_id, $input_pept_seq, "sequence");
        }
        if (my $input_origin_id = $c->req->param("origin_id")) {
            Viroverse::epitopedb::input::update_peptide($schema, $pept_id, $input_origin_id, "origin_id");
        }
        if (my $input_gene_id = $c->req->param("gene_id")) {
            Viroverse::epitopedb::input::update_peptide($schema, $pept_id, $input_gene_id, "gene_id");
        }
        if (my $input_hxb2_start = $c->req->param("hxb2_start")) {
            Viroverse::epitopedb::input::update_peptide($schema, $pept_id, $input_hxb2_start, "position_hxb2_start");
        }
        if (my $input_hxb2_end = $c->req->param("hxb2_end")) {
            Viroverse::epitopedb::input::update_peptide($schema, $pept_id, $input_hxb2_end, "position_hxb2_end");
        }
    }

    $c->stash->{status} = "updated";
    $c->stash->{template} = 'epitopedb/epitopedb_input_sidebar.tt';
}

sub skip : Local {
    my ($self, $c) = @_;

    $c->stash->{status} = "skip";
    $c->stash->{template} = 'epitopedb/epitopedb_input_sidebar.tt';
}


1;