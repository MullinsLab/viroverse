use strict;
use warnings;

package Viroverse::Controller::admin::scientist;
use base 'Viroverse::Controller';
use Catalyst::ResponseHelpers;
use List::Util qw{any none};
use namespace::autoclean;

sub section { "admin" }

sub base : ChainedParent PathPart('scientist') CaptureArgs(0) {
    my ($self, $c) = @_;
    return Forbidden($c)
        unless $c->stash->{scientist}->is_admin;
}

sub index : Chained('base') PathPart('') Args(0) {
    my ($self, $c) = @_;
    my @scientists = $c->model("ViroDB::Scientist")->search({}, {order_by => [{-desc => "role"}, {-asc => "name"}]})->all;
    my @groups     = $c->model('ViroDB::ScientistGroup')->search({display => 1}, {order_by => [{-asc => "name"}]})->all;
    $c->stash(
        scientists      => \@scientists,
        groups          => \@groups,
        template        => 'admin/scientist/index.tt'
    );
    $c->detach('Viroverse::View::NG');
}

sub add : POST Chained('base') PathPart('add') Args(0) {
    my ($self, $c) = @_;
    my $params     = $c->req->params;
    my @missing;
    for my $var ("name", "username", "email", "groups") {
        push @missing, $var unless $params->{$var} and $params->{$var} =~ /\S/;
    }
    if (@missing) {
        my $mid = $c->set_error_msg("Scientist ". ( join ", ", @missing ) . ( @missing > 1 ? " are" : " is" ) . " required");
        return Redirect($c, $self->action_for('index'), { mid => $mid });
    }
    my $scientist = $c->model("ViroDB::Scientist")->create({
        name              => $params->{name},
        username          => $params->{username},
        email             => $params->{email},
        role              => $params->{role},
        group_memberships => [
            {scientist_group_id => $params->{groups}}
        ]
    });
    my $mid = $c->set_status_msg("Added $params->{role} $params->{name}");
    return Redirect($c, $self->action_for('index'), { mid => $mid });
}

sub load : Chained('base') PathPart('') CaptureArgs(1) {
  my ($self, $c, $id) = @_;
  my $scientist = $c->model("ViroDB::Scientist")->find($id)
         or return NotFound($c, "No such scientist «$id»");
  $c->stash( current_model_instance => $scientist );
}

sub edit_scientist : Chained('load') PathPart('edit_scientist') Args(0) {
    my ($self, $c) = @_;
    my $scientist  = $c->model;
    my @groups     = $c->model('ViroDB::ScientistGroup')->search({display => 1}, {order_by => [{-asc => "name"}]})->all;
    my @group_memberships = map { $_->scientist_group_id }
        $scientist->group_memberships->all;
    $c->stash(
        group_memberships     => \@group_memberships,
        groups                => \@groups,
        scientist_to_update   => $scientist,
        template              => 'admin/scientist/edit_scientist.tt'
    );
    $c->detach('Viroverse::View::NG');
}

sub confirmed_change : POST Chained('load') PathPart('edit_scientist') Args(0) {
    my ($self, $c)         = @_;
    my $params             = $c->req->params;
    my $scientist          = $c->model;
    my $name               = $scientist->name;
    my $message            = "";
    my @desired_group_ids  = ref $params->{group_id} eq "ARRAY" ? @{$params->{group_id}} : ($params->{group_id} // () );
    my @existing_group_ids = map { $_->scientist_group_id }
        $scientist->group_memberships->all;
    my @intersection       = grep { my $d = $_; any{ $_  == $d } @existing_group_ids } @desired_group_ids;
    my @groups_to_add      = grep { my $d = $_; none{ $_ == $d } @intersection } @desired_group_ids;
    my @groups_to_delete   = grep { my $e = $_; none{ $_ == $e } @intersection } @existing_group_ids;
    if ($params->{role} ne $scientist->role) {
        $message .= "$name\'s role changed to $params->{role}";
        $scientist->update({
            role => $params->{role}
        });
    }
    $scientist->group_memberships->search({scientist_group_id => \@groups_to_delete})->delete;
    for my $group_id (@groups_to_add) {
        $scientist->group_memberships->create({scientist_group_id => $group_id});
    }
    if (@groups_to_add || @groups_to_delete) {
        if ($message eq "") {
            $message  = "$name\'s groups were changed";
        } else {
            $message .= " and groups were changed";
        }
    }
    if ($message eq "") {
        $message = "No changes were made for $name";
    }
    my $mid = $c->set_status_msg($message);
    return Redirect($c, $self->action_for('index'), { mid => $mid });
}

1;
