
package Viroverse::Controller::input::epitopedb::epitope;
use base 'Viroverse::Controller';

use strict;
use warnings;

use Viroverse::epitopedb::input;
use Viroverse::epitopedb::search;
use EpitopeDB;
use File::chdir;
use File::Path;
use File::Temp;
use Net::FTP;

use Data::Dumper;
use Carp;

=head1 NAME

Viroverse::Controller::input::epitopedb::epitope - Holds Catalyst actions under /input/epitopedb/epitope to add with epitope/mutant data to VV

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
    $context->stash->{sources} = Viroverse::epitopedb::search::get_sources($schema);
    $context->stash->{'cohorts'} = $context->model("ViroDB::Cohort")->list_all;
    $context->stash->{template} = 'epitopedb/epitope.tt';
}

sub result : Local {
    my ($self, $c) = @_;
    my $type = $c->req->param("type");
    my $ept_name = uc $c->req->param("ept_name");
    my $ept_seq = uc $c->req->param("ept_seq");
    my $mut_name = uc $c->req->param("mut_name");
    my $mut_seq = uc $c->req->param("mut_seq");
    my $source_id = $c->req->param("source");
    my ($eptp_id, $status, $mut_id);

    my $ept_pept_id = Viroverse::epitopedb::input::get_pept_id($schema, $ept_name, $ept_seq);

    if (!$ept_pept_id) {
        $c->response->body('Error: unable to resolve wild-type peptide, please import the peptide first');
        return;
    }

    if ($type eq "epitope_result") {
        ($eptp_id, $status) = Viroverse::epitopedb::input::get_eptp_id($schema, $ept_pept_id, $source_id, $type);
    }else {
        my $mut_pept_id = Viroverse::epitopedb::input::get_pept_id($schema, $mut_name, $mut_seq);

        if (!$mut_pept_id) {
            $c->response->body('Error: unable to resolve mutant peptide, please import the peptide first');
            return;
        }
        $mut_id = Viroverse::epitopedb::input::get_mut_id($schema, $mut_pept_id);
        ($eptp_id) = Viroverse::epitopedb::input::get_eptp_id($schema, $ept_pept_id, $source_id, $type);
        $status = Viroverse::epitopedb::input::check_epitope_mutant($schema, $eptp_id, $mut_id, $c);
    }

    if ($status ne "new" && $status ne "exist") {
        if ($status->{eptp}) {
            $c->stash->{eptp_id} = $eptp_id;
            $c->stash->{exist_source} = Viroverse::epitopedb::input::get_source_by_eptp_id($schema, $eptp_id);
            $c->stash->{input_source} = Viroverse::epitopedb::input::get_source_by_source_id($schema, $source_id);
        }elsif ($status->{mut}) {
            $c->stash->{eptp_id} = $eptp_id;
            $c->stash->{mut_id} = $mut_id;
            $c->stash->{patient_id} = $c->req->param('patient');
            $c->stash->{exist_note} = Viroverse::epitopedb::input::get_epitope_mutant_note($schema, $eptp_id, $mut_id, $c);
            $c->stash->{input_note} = $c->req->param('note');
        }
    }
    $c->stash->{type} = $type;
    $c->stash->{status} = $status;
    $c->stash->{template} = 'epitopedb/epitopedb_input_sidebar.tt';

}



1;
