use strict;
use warnings;
use utf8;
use 5.018;

package Viroverse::Controller::Primer;
use Moose;
use Catalyst::ResponseHelpers qw< :helpers :status >;
#use JSON::MaybeXS;
use namespace::autoclean;

BEGIN { extends 'Viroverse::Controller' }

sub base : Chained('/') PathPart('primer') CaptureArgs(0) { }

sub index : Chained('base') PathPart('') Args(0) {
    my ($self, $c) = @_;
    $c->stash( template => 'primer/index.tt' );
    $c->detach( $c->view("NG") );
}

sub load : Chained('base') PathPart('') CaptureArgs(1) {
    my ($self, $c, $id) = @_;
    my $primer = $c->model('ViroDB::Primer')->find($id)
        or return NotFound($c, "No such primer «$id»");
    $c->stash( current_model_instance => $primer );
}

sub download_fasta : Chained('load') PathPart('fasta') Args(0) {
    my ($self, $c) = @_;

    my $primer = $c->model;

    my $fasta = sprintf ">%s\n%s\n", $primer->name, $primer->sequence_bases;

    my $basename = $primer->name;
    $basename =~ s/[^-_.a-zA-Z0-9]/_/g;

    return FromCharString($c,
        $fasta,
        'text/plain; charset=UTF-8',
        [ 'Content-Disposition' => "attachment; filename=$basename.fasta"]);
}

1;
