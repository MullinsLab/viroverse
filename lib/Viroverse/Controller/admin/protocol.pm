use strict;
use warnings;

package Viroverse::Controller::admin::protocol;
use base 'Viroverse::Controller';
use Catalyst::ResponseHelpers;
use Viroverse::Model::protocol;
use Viroverse::Model::protocol_type;
use namespace::autoclean;

sub section { "admin" }

sub base : ChainedParent PathPart('protocol') CaptureArgs(0) {
    my ($self, $c) = @_;
    return Forbidden($c)
        unless $c->stash->{scientist}->is_admin;
}

sub index : Chained('base') PathPart('') Args(0) {
    my ($self, $c) = @_;
    my @protocols = Viroverse::Model::protocol->retrieve_all;
    my @types = Viroverse::Model::protocol_type->retrieve_all;

    $c->stash(
        protocols      => \@protocols,
        protocol_types => \@types,
        template       => 'admin/protocol/index.tt',
    );
    $c->detach('Viroverse::View::NG');
}

sub add : POST Chained('base') PathPart('add') Args(0) {
    my ($self, $c) = @_;
    my $params = $c->req->params;
    my @missing;
    push @missing, "name" unless $params->{name} and $params->{name} =~ /\S/;
    push @missing, "type" unless $params->{protocol_type_id};
    if (@missing) {
        my $mid = $c->set_error_msg("Protocol ". ( join ", ", @missing ) . ( @missing > 1 ? " are" : " is" ) . " required");
        return Redirect($c, $self->action_for('index'), { mid => $mid });
    }

    my $protocol = Viroverse::Model::protocol->insert({
            name             => $params->{name},
            protocol_type_id => $params->{protocol_type_id},
        });

    my $mid = $c->set_status_msg("Added protocol $params->{name}");
    return Redirect($c, $self->action_for('index'), { mid => $mid });
}

sub add_type : POST Chained('base') PathPart('add_type') Args(0) {
    my ($self, $c) = @_;
    my $params = $c->req->params;

    return $self->user_error($c, "Protocol type name is required")
        unless $params->{name};

    my $type = Viroverse::Model::protocol_type->insert({ name => $params->{name} });

    my $mid = $c->set_status_msg("Added protocol type $params->{name}");
    return Redirect($c, $self->action_for('index'), { mid => $mid });
}

1;
