use strict;
use warnings;
use 5.018;
use utf8;

package Viroverse::Controller::Sequence;
use Moose;
use Archive::Zip;
use Catalyst::ResponseHelpers qw< :helpers :status >;
use IO::String;
use JSON::MaybeXS;
use Viroverse::AlignmentVisualization;
use Viroverse::SampleTree;
use namespace::autoclean;

BEGIN { extends 'Viroverse::Controller' }

sub base : Chained('/') PathPart('sequence') CaptureArgs(0) { }

sub load : Chained('base') PathPart('') CaptureArgs(1) {
    my ($self, $c, $id) = @_;
    my $seq = $c->model('sequence::dna')->retrieve($id)
        or return NotFound($c, "No such sequence «$id»");
    $c->stash( current_model_instance => $seq );
}

sub index : Chained('base') PathPart('') Args(0) {
    my ($self, $c) = @_;
    $c->stash( template => 'sequence/index.tt' );
    $c->detach( $c->view("NG") );
}

sub name_parts : Chained('base') PathPart('name_parts') Args(0) {
    my ($self, $c) = @_;
    my $name_parts = $c->model('sequence')->name_parts_sorted;

    # XXX TODO: Use AsJSON once our View::JSON and View::JSON2 aren't stupid.
    # -trs, 6 Dec 2016
    return FromCharString($c,
        JSON->new->encode( $name_parts ),
        'application/json; charset=UTF-8'
    );
}

sub show : Chained('load') PathPart('') Args(0) {
    my ($self, $c) = @_;

    my $cds = $c->model->hxb2_cds;
    if ($cds) {
        # Make the returned categories mutually exclusive
        my %covers = map {; $_ => 1 } @{$cds->{covers}};
        $cds->{overlaps} = [ grep { not $covers{$_} } @{$cds->{overlaps}} ];
    }

    my $virodb_sequence = $c->model("ViroDB::NucleicAcidSequence")->find_by_idrev($c->model->idrev);

    $c->controller('sidebar')->sidebar_to_stash($c);

    $c->stash(
        template        => 'sequence/show.tt',
        sequence        => $c->model,
        virodb_sequence => $virodb_sequence,
        cds             => $cds,
        sequence_origin =>
            Viroverse::SampleTree->new(
                current_node    => $c->model,
                intended_sample => $c->model->sample_id,
            ),

        alignment_visualization =>
            Viroverse::AlignmentVisualization->new(
                sequence          => $c->model,
                reference_regions => [ $c->model("ViroDB::GenomeRegion")->cds_regions ],
            ),
    );

    $c->detach( $c->view("NG") );
}

sub delete : Chained('load') PathPart('') Args(0) DELETE {
    my ($self, $c) = @_;

    my $seq = $c->model;
    my $why = $c->req->param('reason');

    my ($ok, $msg) = $seq->mark_deleted_by($c->stash->{scientist}, $why);

    return ClientError($c, $msg) unless $ok;

    return FromCharString($c,
        JSON->new->encode( { ok => $ok } ),
        'application/json; charset=UTF-8'
    );
}

sub redirect_summary_sequence : Path('/summary/sequence') Args {
    my ($self, $c, $id) = @_;
    my $url = defined $id
        ? $c->uri_for_action($self->action_for("show"), [ $id ])
        : $c->uri_for_action($self->action_for("index"));
    return RedirectToUrl($c, $url, HTTP_MOVED_PERMANENTLY);
}

sub load_virodb : Chained('load') PathPart('') CaptureArgs(0) {
    my ($self, $c, $idrev) = @_;
    my $sequence = $c->model("ViroDB::NucleicAcidSequence")->find_by_idrev($c->model->idrev)
        or return NotFound($c, "No such sequence «$idrev»");
    $c->stash( current_model_instance => $sequence );
}

sub revise : Chained('load_virodb') PathPart('revise') Args(0) {
    my ($self, $c) = @_;

    return Forbidden($c)
        unless $c->model->scientist_can_revise( $c->stash->{scientist} );

    my @scientists = $c->model("ViroDB::Scientist")->active->order_by("name");
    $c->stash(
        sequence   => $c->model,
        template   => 'sequence/revise.tt',
        scientists => \@scientists,
    );
    $c->detach( $c->view("NG") );
}

sub create_revision : POST Chained('load_virodb') PathPart('revise') Args(0) {
    my ($self, $c) = @_;

    return Forbidden($c)
        unless $c->model->scientist_can_revise( $c->stash->{scientist} );

    my $success = sub {
        my $idrev = shift;
        my $mid = $c->set_status_msg("Created a new revision");
        return Redirect($c, $self->action_for('show'), [ $idrev ], { mid => $mid });
    };

    my $error = sub {
        my $msg = shift;
        my $mid = $c->set_error_msg($msg);
        return Redirect($c, $self->action_for('revise'), [ $c->model->idrev ], { mid => $mid });
    };

    my %revised = (
         map {; $_ => $c->req->params->{$_} }
        grep { $c->req->params->{$_} }
           qw[ name sequence scientist_id na_type note ]
    );

    if (exists $revised{sequence}) {
        # Strip any fasta description line which may have snuck in
        $revised{sequence} =~ s/\A\s*>.*$//m;

        # Bail out if we see evidence of more than a single sequence via
        # another stray description line
        return $error->("No changes made. It looks like you pasted a multi-sequence FASTA into the sequence content field.")
            if $revised{sequence} =~ /^\s*>/m;

        # Strip all whitespace, including newlines
        $revised{sequence} =~ s/[\r\n\s]+//g;
    }

    my $new_rev = $c->model->create_revision(\%revised);

    return $new_rev
        ? $success->( $new_rev->idrev )
        : $error->("No changes made. A revised sequence must differ from the original.");
}

sub create_note : POST Chained('load_virodb') PathPart('notes') Args(0) {
    my ($self, $c) = @_;
    return Forbidden($c) unless $c->stash->{scientist}->can_edit;
    $c->model->notes->create({
        body         => $c->req->params->{body},
        scientist_id => $c->stash->{scientist}->scientist_id,
    });
    return Redirect($c, $self->action_for("show"), [ $c->model->idrev ]);
}

sub chromats : Chained('load_virodb') PathPart('chromats') Args(0) {
    my ($self, $c) = @_;
    my $sequence   = $c->model;

    # Create a zip of all chromats.  We add them at the top level because macOS
    # and Windows will automatically extract zip files into directories named
    # after the zip file itself, and we don't want an extra level of
    # directories.
    my $zip = Archive::Zip->new;

    $zip->addString( $_->data, join("-", $sequence->idrev, $_->name) )
        for $sequence->chromats;

    # Write out zip file to an in-memory handle
    my $body = IO::String->new;
    my $rv = $zip->writeToFileHandle($body);
    return ServerError($c, 'Problem writing zip file')
        unless $rv == Archive::Zip::AZ_OK;
    $body->seek(0, 0);

    # Some reasonable filename
    my $filename =
        join "-",
         map { s/[^A-Za-z0-9_.-]+/_/gr }
             $sequence->idrev,
             $sequence->name,
             "chromats";

    return FromHandle($c,
        $body,
        'application/zip',
        [ 'Content-Disposition' => "attachment; filename=$filename.zip" ],
    );
}

1;
