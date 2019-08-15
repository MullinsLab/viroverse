use strict;
use warnings;
use utf8;
use 5.018;

package Viroverse::Controller::PacBioSequencing;
use Moose;
use Catalyst::ResponseHelpers;
use Try::Tiny;
use Viroverse::SampleTree;
use namespace::autoclean;

BEGIN { extends 'Viroverse::Controller' }

sub base : Chained('/') PathPart('pacbio') CaptureArgs(0) { }

sub index : Chained('base') PathPart('') Args(0) {
    my ($self, $c) = @_;
    $c->stash( template => 'pacbio/index.tt' );
    $c->detach( $c->view("NG") );
}

1;
