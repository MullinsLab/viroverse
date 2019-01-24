package Viroverse::Controller::summary::alignment;
use strict;
use warnings;
use Catalyst::ResponseHelpers;
use base 'Viroverse::Controller';

sub section { 'browse' }

sub load : Chained PathPart('summary/alignment') CaptureArgs(1) {
    my ($self, $c, $id) = @_;
    my $alignment = Viroverse::Model::alignment->retrieve($id);
    unless ($alignment) {
        NotFound($c, "Not found");
        $c->detach;
    }
    $c->stash( current_model_instance => $alignment );
}

sub display : Chained('load') PathPart('') Args(0)  {
    my ($self,$context) = @_;
    $context->stash->{alignment} = $context->model;
    $context->stash->{template} = 'sum-alignment.tt';
}

sub export_fasta : Chained('load') PathPart('export/fasta') Args {
    my ($self, $c) = @_;
    my $alignment = $c->model;
    my $fasta     = $alignment->fasta
        or return ServerError($c, "Failed to retrieve fasta for alignment #" . $alignment->idrev);

    $c->response->content_type('text/plain');
    $c->response->header( 'Content-Disposition' => 'attachment; filename=viroverse-alignment-' . $alignment->idrev . '.fal' );
    $c->response->body( $fasta );
}

sub export_pairwise : Chained('load') PathPart('export/pairwise') Args {
    my ($self, $c) = @_;
    my $alignment = $c->model;
    my @pieces  = $alignment->pairwise_ops;
    my @columns = qw[operation sequence_start sequence_end reference_start reference_end];

    $c->response->header("Content-type", "text/csv; charset=UTF-8");
    $c->response->header("Content-disposition", 'attachment; filename="viroverse-alignment-' . $alignment->idrev . '-reference-anchored.csv"');
    $c->response->body( join "\n",
        join(",", @columns),
        (map { join ",", @$_{@columns} } @pieces),
        "",
    );
    $c->detach;
}

1;
