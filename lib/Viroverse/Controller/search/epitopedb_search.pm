package Viroverse::Controller::search::epitopedb_search;
use base 'Viroverse::Controller';

use strict;
use warnings;

#use Viroverse::epitopedb::search;
#use EpitopeDB;

use File::chdir;
use File::Path;
use File::Temp;
use Net::FTP;

use Data::Dumper;
use Carp;

use Catalyst::ResponseHelpers qw< :helpers :status >;


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
sub section {
    return 'browse';
}

sub auto : Private {
    my ( $self, $context ) = @_;

    unless ($context->stash->{features}->{epitopedb}) {
        return NotFound($context, "Feature disabled: EpitopeDB");
    }
}

sub index : Private {
    my ($self, $context) = @_;
    $context->forward('peptide');
}

sub peptide : Local {
    my ( $self, $context ) = @_;
    $context->stash->{'cohorts'} = $context->model("ViroDB::Cohort")->list_all;
    my $schema = EpitopeDB->connect($Viroverse::config::dsn, $Viroverse::config::read_only_user,$Viroverse::config::read_only_pw);

    $context->stash->{genes} = Viroverse::epitopedb::search::get_genes($schema);
    $context->stash->{hlas} = Viroverse::epitopedb::search::get_hlas($schema);
    $context->stash->{patients} = Viroverse::epitopedb::search::get_patients($schema);
#    $context->stash->{genes} = [$context->model('EpitopeDB::gene')->all];
    $context->stash->{template} = 'epitopedb_search/peptide.tt';
}

sub pool : Local {
    my ( $self, $context ) = @_;

#    $context->stash->{'cohorts'} = $context->model("ViroDB::Cohort")->list_all;
    my $schema = EpitopeDB->connect($Viroverse::config::dsn, $Viroverse::config::read_only_user,$Viroverse::config::read_only_pw);

    $context->stash->{pools} = Viroverse::epitopedb::search::get_pools($schema);
    $context->stash->{template} = 'epitopedb_search/pool.tt';
}


1;
