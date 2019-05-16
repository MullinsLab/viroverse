package Viroverse::Controller::search::epitopedb_search::peptide;
use base 'Viroverse::Controller';

use strict;
use warnings;

use Viroverse::epitopedb::search;
#use EpitopeDB::peptide;

use File::chdir;
use File::Path;
use File::Temp;
use Net::FTP;

use Data::Dumper;
use Carp;

=head1 NAME

Viroverse::Controller::search::epitopedb - Holds Catalyst actions under /search/epitopedb to retrive ELISpot data from VV

=head1 SYNOPSIS

See L<Viroverse>

=head1 DESCRIPTION

Catalyst Controller.     

=head1 METHODS

=cut

=item begin
=cut

my $schema = EpitopeDB->connect(Viroverse::Config->conf->{dsn}, Viroverse::Config->conf->{read_only_user},Viroverse::Config->conf->{read_only_pw});

sub section {
    return 'browse';
}

sub index : Private {
    my ($self, $context) = @_;

    $context->stash->{genes} = Viroverse::epitopedb::search::get_genes($schema);
    $context->stash->{sources} = Viroverse::epitopedb::search::get_sources($schema);
    $context->stash->{hlas} = Viroverse::epitopedb::search::get_hlas($schema);
    $context->stash->{patients} = Viroverse::epitopedb::search::get_patients($schema);
    $context->stash->{template} = 'epitopedb_search/peptide.tt';
}

sub result : Local {
    my ( $self, $context ) = @_;

    my @pept_genes = $context->req->param('pept_gene');
    my @epit_genes = $context->req->param('epit_gene');
    if (@epit_genes) {
        $context->stash->{search_flag} = "Epitope";
    }else {
        $context->stash->{search_flag} = "Peptide";
    }

    $context->stash->{results} = Viroverse::epitopedb::search::pept_search($context, $schema);
    $context->stash->{template} = 'epitopedb_search/result.tt';
}

sub elispot : Local {
    my ($self, $c) = @_;
    $c->stash->{peptide} = Viroverse::epitopedb::search::get_pept($c, $schema);
    $c->stash->{patient} = Viroverse::epitopedb::search::get_patient($c, $schema);
    $c->stash->{elispots} = Viroverse::epitopedb::search::get_elispot($c, $schema);
    $c->stash->{template} = 'epitopedb_search/elispot.tt';
}

sub titration : Local {
    my ($self, $c) = @_;
    $c->stash->{peptide} = Viroverse::epitopedb::search::get_pept($c, $schema);
    $c->stash->{patient} = Viroverse::epitopedb::search::get_patient($c, $schema);
    $c->stash->{titrations} = Viroverse::epitopedb::search::get_titration($c, $schema);
    $c->stash->{template} = 'epitopedb_search/titration.tt';
}

sub hla_restriction : Local {
    my ($self, $c) = @_;
    $c->stash->{peptide} = Viroverse::epitopedb::search::get_pept($c, $schema);
    $c->stash->{patient} = Viroverse::epitopedb::search::get_patient($c, $schema);
    $c->stash->{hla_restrictions} = Viroverse::epitopedb::search::get_hla_restriction($c, $schema);
    $c->stash->{template} = 'epitopedb_search/hla_restriction.tt'; 
}

sub mutant : Local {
    my ($self, $c) = @_;
    $c->stash->{peptide} = Viroverse::epitopedb::search::get_pept($c, $schema);
    $c->stash->{patient} = Viroverse::epitopedb::search::get_patient($c, $schema);
    $c->stash->{mutants} = Viroverse::epitopedb::search::get_mutant($c, $schema);
    $c->stash->{template} = 'epitopedb_search/mutant.tt'; 
}

sub show_figure : Local {
    my ($self, $c) = @_;
    my $type = $c->req->param('type');
    my $pept = $c->req->param('pept');
    my $edate = $c->req->param('edate');
    my $sdate = $c->req->param('sdate');
    my $tissue = $c->req->param('tissue');
    my $src = "/static/epitopedb/images/".$type."_".$edate."_".$sdate."_".$pept."_".$tissue.".png";
    $c->stash->{image} = "<a href='$src' target=_blank><img src='$src' height=170px width=300px border=0></a>";
    $c->stash->{template} = 'epitopedb_search/epitopedb_search_sidebar.tt';
}

1;
