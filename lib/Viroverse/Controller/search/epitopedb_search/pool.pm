package Viroverse::Controller::search::epitopedb_search::pool;
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

my $schema = EpitopeDB->connect($Viroverse::config::dsn, $Viroverse::config::read_only_user,$Viroverse::config::read_only_pw);

sub section {
    return 'browse';
}

sub index : Private {
    my ($self, $context) = @_;

    $context->stash->{pools} = Viroverse::epitopedb::search::get_pools($schema);
    $context->stash->{template} = 'epitopedb_search/pool.tt';
}

sub result : Local {
    my ( $self, $context ) = @_;

    $context->stash->{results} = Viroverse::epitopedb::search::pool_search($context, $schema);
    warn "results: ", $context->stash->{results},"\n";
    $context->stash->{template} = 'epitopedb_search/pool_result.tt';
}

sub elispot : Local {
    my ($self, $c) = @_;
    $c->stash->{pool_name} = Viroverse::epitopedb::search::get_pool_name($c, $schema);
    $c->stash->{patient} = Viroverse::epitopedb::search::get_patient($c, $schema);
    $c->stash->{elispots} = Viroverse::epitopedb::search::get_pool_elispot($c, $schema);
    $c->stash->{template} = 'epitopedb_search/pool_elispot.tt';
}

sub matrix : Local {
    my ($self, $c) = @_;
    $c->stash->{exp_date} = Viroverse::epitopedb::search::get_exp_date($c, $schema);
    $c->stash->{sample} = Viroverse::epitopedb::search::get_sample($c, $schema);
    $c->stash->{matrix} = Viroverse::epitopedb::search::get_matrix($c, $schema);
    $c->stash->{template} = 'epitopedb_search/pool_matrix.tt';
}

1;
