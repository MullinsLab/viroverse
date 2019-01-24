package Viroverse::Controller::admin::cohort;
use base 'Viroverse::Controller';
use strict;
use warnings;
use Catalyst::ResponseHelpers;
use List::AllUtils qw< uniq >;
use namespace::clean;

=head1 NAME

Viroverse::Controller::admin::cohort - Cohort administration and management tools

=head1 METHODS

=cut

sub section { 'admin' }

sub base : ChainedParent PathPart('cohort') CaptureArgs(0) {
    my ($self, $c) = @_;
    return Forbidden($c)
        unless $c->stash->{scientist}->is_admin;
}

sub index : Chained('base') PathPart('') Args(0) {
    my ($self, $c) = @_;
    my @cohorts = $c->model('ViroDB::Cohort')->all;
    my @groups  = grep { $_->display }
        $c->model('ViroDB::ScientistGroup')->all;

    $c->stash(
        cohorts     => \@cohorts,
        groups      => \@groups,
        template    => 'admin/cohort/index.tt',
    );
    $c->detach( $c->view("NG") );
}

sub add : POST Chained('base') PathPart('add') Args(0) {
    my ($self, $c) = @_;
    my $params = $c->req->params;
    return $self->user_error($c, "Cohort name is required")
        unless $params->{name} and $params->{name} =~ /\S/;

    my $txn    = $c->model('ViroDB')->schema->txn_scope_guard;
    my $cohort = $c->model('ViroDB::Cohort')
        ->create({ name => $params->{name} });
    $cohort->discard_changes;
    $txn->commit;

    my $mid = $c->set_status_msg("Added cohort $params->{name}");
    return Redirect($c, $self->action_for('index'), { mid => $mid });
}

1;
