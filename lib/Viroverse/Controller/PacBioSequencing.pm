use strict;
use warnings;
use utf8;
use 5.018;

package Viroverse::Controller::PacBioSequencing;
use Moose;
use Catalyst::ResponseHelpers;
use Try::Tiny;
use Viroverse::SampleTree;
use Fasta;
use namespace::autoclean;

BEGIN { extends 'Viroverse::Controller' }

sub base : Chained('/') PathPart('pacbio') CaptureArgs(0) {
    my ($self, $c) = @_;
    unless ($c->stash->{features}->{pacbio_sequencing}) {
        return NotFound($c, "Feature disabled: PacBio sequencing");
    }
}

sub index : Chained('base') PathPart('') Args(0) {
    my ($self, $c) = @_;
    $c->stash( template => 'pacbio/index.tt' );
    $c->detach( $c->view("NG") );
}

sub load_pool_product : Chained('base') PathPart('') CaptureArgs(1) {
    my ($self, $c, $id) = @_;
    my $pcr;
    if ($c->req->params->{pcr_product}) {
        $pcr = $c->model("ViroDB::PolymeraseChainReactionProduct")
                    ->find($id)
            or return NotFound($c, "No such PCR product «$id»");
    } else {
        $pcr = $c->model("ViroDB::PacbioPool")->find({ pcr_product_id => $id })
            or return NotFound($c, "No such PacBio pool PCR product «$id»");
    }
    $c->stash( current_model_instance => $pcr );
}

sub add_sequences : GET Chained('load_pool_product') PathPart('sequences') Args(0) {
    my ($self, $c) = @_;
    return Forbidden($c) unless $c->stash->{scientist}->can_edit;
    $c->stash(
        pool           => $c->model,
        template       => 'pacbio/add_sequences.tt',
        scientists     =>
            [ $c->model("ViroDB::Scientist")->active->order_by("name")->all ],
        sequence_types =>
            [ $c->model("ViroDB::SequenceType")->order_by("name")->all ],
    );
    $c->detach( $c->view("NG") );
}

sub upload_sequences : POST Chained('load_pool_product') PathPart('sequences') Args(0) {
    my ($self, $c) = @_;
    return Forbidden($c) unless $c->stash->{scientist}->can_edit;
    my $sequences = Fasta::string2array(
        \($c->req->upload("sequence_file")->slurp)
    );
    my $created_count;
    my $txn = $c->model("ViroDB")->schema->txn_scope_guard;
    for my $seq (@$sequences) {
        my $new_sequence = $c->model("ViroDB::NucleicAcidSequence")->create({
            name             => $seq->{id},
            sequence         => $seq->{seq},
            scientist_id     => $c->req->params->{scientist_id},
            pcr_product_id   => $c->model->pcr_product_id,
            sample_id        => $c->model->input_sample->id,
            sequence_type_id => $c->req->params->{sequence_type_id},
            na_type          => $c->req->params->{na_type},
        });
        $new_sequence->discard_changes;
        $new_sequence->notes->create({
                body => $seq->{description},
                scientist_id => $c->req->params->{scientist_id}
            }) if $seq->{description};
        $new_sequence->notes->create({
            body => $c->req->params->{note},
            scientist_id => $c->req->params->{scientist_id}
        }) if $c->req->params->{note};
        $created_count++;
    }
    $txn->commit;
    my $mid = $c->set_status_msg("Created $created_count sequences");
    return Redirect($c, $self->action_for("index"), { mid => $mid, rows => 12 });
}

1;
