package Viroverse::Controller::Root;

use strict;
use warnings;
use base 'Viroverse::Controller';

use Catalyst::ResponseHelpers;
require Viroverse::config;

# remove Root from namespace so that it's like they're in Viroverse.pm
__PACKAGE__->config->{namespace} = '';

=head1 NAME

Viroverse::Controller::Root - Controller for Viroverse's root path

=head1 SYNOPSIS

See L<Viroverse>

=head1 DESCRIPTION

=head1 METHODS

=head2 auto

Primarily handles scientist authentication via REMOTE_USER and stashes a
L<Viroverse::session> object.

Additionally stashes the following values:

=over

=item C<< $c->stash->{scientist} >>

=item C<< $c->req->env->{"viroverse.scientist"} >>

Set to the currently logged in L<Viroverse::Model::scientist> record.

=item C<< $c->stash->{debug} >>

Reflects state of C<< $c->debug >>, which reflects C<$Viroverse::config::debug>.

=back

=cut

sub auto : Private {
    my ($self, $context) = @_;

    $context->stash->{uri_base} = $context->uri_for("/");

    $context->stash->{session} = Viroverse::session->new;

    $context->stash->{help_email} = $Viroverse::config::help_email;
    my $auth_error = sub {
        $context->stash->{error_msg}  = shift || "Authentication error";
        $context->stash->{help_name}  = $Viroverse::config::help_name;
        $context->stash->{template}   = 'auth-error-minimal.tt';
        $context->detach("View::TT");
    };

    my $username = $context->req->remote_user;
    unless ($username) {
        # Remote user should never be empty in production; if it is, something is misconfigured.
        $context->log->error( "Request from " . $context->req->address . " without REMOTE_USER!?" );
        return $auth_error->("You are not logged in.");
    }

    my $sci = ViroDB->instance->resultset("Scientist")->find({ username => $username });
    if ($sci and not $sci->is_retired) {
        $context->stash->{scientist} = $sci;
        $context->req->env->{'viroverse.scientist'} = $sci;
    } else {
        return $auth_error->("You are logged in, but do not have a Viroverse user.");
    }

    #  Setting Viroverse Authorization paramaters
    $context->stash->{debug} = $context->debug();

    my $agent = $context->req->user_agent || '';
    my $uri = $context->req->uri;
    $context->stash->{help_body} = <<"END";

---- Add your question above this line ----
scientist: $username
uri: $uri
browser: $agent
END

    $context->stash->{features} = $Viroverse::config::features;

    $context->load_status_msgs;

    return 1;
}

=head2 default

Return a 404 response if we get here

=cut

sub default : Private {
    my ($self, $c) = @_;
    return NotFound($c);
}

=head2 end

Rollback any outstanding transactions if AutoCommit is not enabled.  Assumes
that any outstanding transactions are failures.

Forward to View::TT unless we have a response body or there's no template in
the stash (e.g. from Controller::enum).

=cut

sub end : Private {
    my ($self, $context) = @_;

    Viroverse::CDBI->db_Main->rollback() unless Viroverse::CDBI->db_Main->{AutoCommit};

    $context->forward('Viroverse::View::TT')
        unless $context->has_errors
            or $context->response->has_body
            or not $context->stash->{template};
}

1;
