use strict;
use warnings;
use utf8;
use 5.018;

package Viroverse::Controller::Sample;
use Moose;
use Catalyst::ResponseHelpers qw< :helpers :status >;
use JSON::MaybeXS;
use namespace::autoclean;
use Excel::Writer::XLSX;
use IO::String;
use Viroverse::ISLAWorksheet;

BEGIN { extends 'Viroverse::Controller' }

sub redirect_sample_details : Path('/summary/sample/details') Args(1) {
    my ($self, $c, $id) = @_;
    my $url = $c->uri_for_action($self->action_for("show"), [ $id ]);
    return RedirectToUrl($c, $url, HTTP_MOVED_PERMANENTLY);
}

sub base : Chained('/') PathPart('sample') CaptureArgs(0) { }

sub index : Chained('base') PathPart('') Args(0) {
    my ($self, $c) = @_;
    $c->stash( template => 'sample/index.tt' );
    $c->detach( $c->view("NG") );
}

sub load : Chained('base') PathPart('') CaptureArgs(1) {
    my ($self, $c, $id) = @_;
    my $sample = $c->model("ViroDB::Sample")->find($id)
        or return NotFound($c, "No such sample «$id»");
    $c->stash( current_model_instance => $sample );
}

sub mutate : Chained('load') PathPart('') CaptureArgs(0) {
    my ($self, $c) = @_;
    return Forbidden($c) unless $c->stash->{scientist}->can_edit;
}

sub show_json : Chained('load') PathPart('') Args(0)
              : Does(MatchRequestAccepts) Accept('application/json') {
    my ($self, $c) = @_;

    my $search_data = $c->model->search_data;

    return FromCharString($c,
        JSON->new->convert_blessed->encode($search_data),
        'application/json; charset=UTF-8'
    );
}

sub page_base : Chained('load') PathPart('') CaptureArgs(0) {
    my ($self, $c) = @_;
    my $related_samples = Viroverse::SampleTree->new(current_node => $c->model);
    $c->stash(
        sample          => $c->model,
        related_samples => $related_samples,
    );
}

sub show : Chained('page_base') PathPart('') Args(0) {
    my ($self, $c) = @_;

    my @extractions = sort { $b->{date_completed} cmp $a->{date_completed} } map {
        {
            type => $_->extract_type->name,
            concentration => ( $_->concentration_unit ?
                $_->concentration . " " . $_->concentration_unit->name :
                "unknown concentration"),
            date_completed => $_->date_completed,
        }
    } $c->model->extractions;

    my @sequence_ids = map { $_->idrev }
        $c->model->na_sequences->latest_revisions->with_type("Genomic");

    my @overlaps = map {
        my $cds = $_->hxb2_cds;
        if ( defined $cds ) {
            join(", ", @{$cds->{overlaps}});
        } else {
            "not aligned";
        }
    } $c->model("sequence::dna")->retrieve_many(@sequence_ids);
    my %freq;
    $freq{$_}++ for @overlaps;

    $c->stash(
        template      => 'sample/show.tt',
        extractions   => \@extractions,
        sequence_freq => \%freq,
    );
    $c->detach( $c->view("NG") );
}

sub assignments : Chained('page_base') PathPart('assignments') Args(0) {
    my ($self, $c) = @_;

    my $projects = [
        $c->model("ViroDB::Project")
            ->order_by( \"upper(name)" )
    ];

    my $scientists = [
        $c->model("ViroDB::Scientist")
            ->active
            ->order_by("name")
    ];

    $c->stash(
        template    => 'sample/assignments.tt',
        projects    => $projects,
        scientists  => $scientists,
    );
    $c->detach( $c->view("NG") );
}

sub sequences : Chained('page_base') PathPart('sequences') Args(0) {
    my ($self, $c) = @_;
    $c->stash(template => 'sample/sequences.tt');
    $c->detach( $c->view("NG") );
}

sub extractions : Chained('page_base') PathPart('extractions') Args(0) {
    my ($self, $c) = @_;
    $c->stash(
        template   => 'sample/extractions.tt',
    );
    $c->detach( $c->view("NG") );
}

sub derivations : Chained('page_base') PathPart('derivations') Args(0) {
    my ($self, $c) = @_;

    my $scientists = [
        $c->model("ViroDB::Scientist")
            ->active
            ->order_by("name")
    ];

    my $protos = [ $c->model("ViroDB::DerivationProtocol")->order_by("name") ];

    $c->stash(
        template => 'sample/derivations.tt',
        protocols   => $protos,
        scientists  => $scientists,
    );
    $c->detach( $c->view("NG") );

}

sub ice_cultures : Chained('page_base') PathPart('ice-cultures') Args(0) {
    my ($self, $c) = @_;

    unless ($c->stash->{features}->{ice_cultures}) {
        return NotFound($c, "Feature disabled: ICE cultures");
    }

    $c->stash(template => 'sample/ice-cultures.tt');
    $c->detach( $c->view("NG") );
}

sub isla_worksheet : Chained('page_base') PathPart('isla-worksheet') Args(0) {
    my ($self, $c) = @_;

    unless ($c->stash->{features}->{isla_worksheet}) {
        return NotFound($c, "Feature disabled: ISLA worksheets");
    }


    my $worksheet = Viroverse::ISLAWorksheet->new(model => $c->model);

    my $id = $c->model->sample_id;
    my $url = $c->uri_for_action($self->action_for("show"), [ $id ]);

    return FromHandle($c, $worksheet->make_xlsx($url), 'application/vnd.ms-excel',
        [ 'Content-Disposition' => "attachment; filename=ISLA_$id.xlsx"]);
}

sub create_note : POST Chained('mutate') PathPart('notes') Args(0) {
    my ($self, $c) = @_;
    $c->model->notes->create({
        body         => $c->req->params->{body},
        scientist_id => $c->stash->{scientist}->scientist_id,
    });
    return Redirect($c, $self->action_for("show"), [ $c->model->id ]);
}

sub new_extraction : Chained('mutate') PathPart('extraction/new') Args(0) {
    my ($self, $c) = @_;
    $c->controller("sidebar")->clear($c, 'sample', 'extraction');
    $c->controller("sidebar")->add($c, sample => $c->model->sample_id);
    return Redirect($c, '/input/extraction' );
}

sub assignment : Chained('mutate') PathPart('assignment') CaptureArgs(0) {
    my ($self, $c) = @_;
    my $project_id = $c->req->params->{project_id};
    my $project = $c->model("ViroDB::Project")->find($project_id)
        or return NotFound($c, "No such project «$project_id»");
    $c->stash( project => $project );
}

sub assign : POST Chained('assignment') PathPart('new') Args(0) {
    my ($self, $c) = @_;
    my $scientist;

    if (my $id = $c->req->params->{scientist_id}) {
        $scientist = $c->model("ViroDB::Scientist")->find($id)
            or return ClientError($c, "No such scientist with id «$id»");
    }

    $c->stash->{project}->assign($c->model, $scientist);
    return Redirect($c, $self->action_for("assignments"), [ $c->model->id ]);
}

sub unassign : POST Chained('assignment') PathPart('delete') Args(0) {
    my ($self, $context) = @_;
    my $project_material = $context->stash->{project}->sample_assignments->search(sample_id => $context->model->sample_id)->single;
    return NotFound($context, "Assignment doesn't exist") unless $project_material;
    $project_material->delete;
    return Redirect($context, $self->action_for("assignments"), [ $context->model->id ]);
}

sub manage_aliquots : Chained('mutate') PathPart('manage-aliquots') Args(0) {
    my ($self, $c) = @_;
    $c->controller('sidebar')->clear($c, 'found_aliquots');
    $c->controller('sidebar')->add($c, 'found_aliquots' => map { $_->id } $c->model->aliquots);
    return Redirect($c, "/freezer/search_freezers/aliquot_search");
}

sub new_rt_product : Chained('mutate') PathPart('rt_product/new') Args(0) {
    my ($self, $c) = @_;
    my $id = $c->stash->{scientist}->scientist_id;
    $c->controller("sidebar")->clear($c, 'rt', 'extraction');
    $c->controller("sidebar")->add($c, extraction => map { $_->id } $c->model->extractions->rna->search({ scientist_id => $id }));
    return Redirect($c, '/input/RT' );
}

sub new_pcr_product : Chained('mutate') PathPart('pcr_product/new') Args(0) {
    my ($self, $c) = @_;
    my $id = $c->stash->{scientist}->scientist_id;
    $c->controller("sidebar")->clear($c, 'rt', 'extraction', 'pos_pcr');
    $c->controller("sidebar")->add($c, rt => map { $_->id } $c->model->extractions->rna->search_related('rt_products', { 'me.scientist_id' => $id }));
    $c->controller("sidebar")->add($c, extraction => map { $_->id } $c->model->extractions->dna->search({ scientist_id => $id }));
    return Redirect($c, '/input/PCR' );
}

sub new_sequence : Chained('mutate') PathPart('sequence/new') Args(0) {
    my ($self, $c) = @_;
    my $id = $c->stash->{scientist}->scientist_id;
    $c->controller("sidebar")->clear($c, 'pcr_more');
    @{$c->session->{sidebar}{pos_pcr}} = map { $_ -> id } $c->model->pcr_products->positive->search({ scientist_id => $id });
    return Redirect($c, '/input/sequence/index');
}

1;
