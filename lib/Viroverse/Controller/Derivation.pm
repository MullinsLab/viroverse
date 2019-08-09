use strict;
use warnings;
use utf8;
use 5.018;

package Viroverse::Controller::Derivation;
use Moose;
use Catalyst::ResponseHelpers;
use Try::Tiny;
use Viroverse::SampleTree;
use Viroverse::Types qw< ExternalReferenceUri >;
use namespace::autoclean;

BEGIN { extends 'Viroverse::Controller' }

sub base : Chained('/') PathPart('derivation') CaptureArgs(0) { }

sub create_with_default_outputs : POST Chained('base') PathPart('create_with_default_outputs') Args(0) {
    my ($self, $c) = @_;

    return Forbidden($c) unless $c->stash->{scientist}->can_edit;

    my %params = %{$c->req->params};
    my $new_derivation = $c->model("ViroDB::Derivation")->create_with_default_outputs({
        input_sample_id        => $params{input_sample_id},
        derivation_protocol_id => $params{protocol_id},
        scientist_id           => $params{scientist_id},
        date_completed         => DateTime->today->ymd,
    });

    Redirect($c, $self->action_for("show"), [ $new_derivation->id ]);
}

sub load : Chained('base') PathPart('') CaptureArgs(1) {
    my ($self, $c, $id) = @_;
    my $derivation = $c->model("ViroDB::Derivation")->find($id)
        or return NotFound($c,"No such derivation «$id»");
    $c->stash( current_model_instance => $derivation );
}

sub show : Chained('load') PathPart('') Args(0) {
    my ($self, $c) = @_;
    my @tissue_types = $c->model("ViroDB::TissueType")->search({}, {order_by => "name"})->all;
    my $related_samples = Viroverse::SampleTree->new(current_node => $c->model);
    $c->stash(
        template        => 'derivation/show.tt',
        derivation      => $c->model,
        tissue_types    => \@tissue_types,
        related_samples => $related_samples,
    );
    $c->detach( $c->view("NG") );
}

sub update : POST Chained('load') PathPart('') Args(0) {
    my ($self, $c) = @_;

    return Forbidden($c) unless $c->stash->{scientist}->can_edit;

    try {
        my $params = $c->req->params;
        ExternalReferenceUri->assert_coerce($params->{uri}) if $params->{uri};
        $c->model->update({
            map {; $_ => $params->{$_} }
                qw[ date_completed uri ]
        });
    } catch {
        my $mid = $c->set_error_msg("Couldn't save derivation details");
        Redirect($c, $self->action_for("show"), [ $c->model->id ], { mid => $mid });
    };
    Redirect($c, $self->action_for("show"), [ $c->model->id ]);
}

sub add_sample : POST Chained('load') PathPart('add_sample') Args(0) {
    my ($self, $c) = @_;

    return Forbidden($c)
        unless $c->stash->{scientist}->is_admin || $c->stash->{scientist}->is_supervisor;

    my $params = $c->req->params;
    try {
        die unless $params->{tissue_type_id};
        $c->model->add_to_output_samples({
            tissue_type_id => $params->{tissue_type_id},
            name           => $params->{name} || undef,
            date_collected => $params->{date_collected} || undef,
        });
    } catch {
        my $mid = $c->set_error_msg("Couldn't create sample");
        Redirect($c, $self->action_for("show"), [ $c->model->id ], { mid => $mid });
    };
    Redirect($c, $self->action_for("show"), [ $c->model->id ]);
}

1;
