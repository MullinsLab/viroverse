use strict;
use warnings;

package Viroverse::Controller;
use base 'Catalyst::Controller';

use Viroverse::session;
use Carp qw <confess croak >;

=head1 NAME

Viroverse::Controller - Base methods for all Viroverse controllers, inherits from Catalyst::Controller

=head1 SYNOPSIS

    package Viroverse::Controller::...;
    use base 'Viroverse::Controller';

    # May override section() in order for menus
    sub section { 'which_menu_section' }

=head1 METHODS

=head2 section

Optional menu section name.

You may overide this method to return which menu section should be
included and highlighted by the template.

The value will be automatically stashed under the key C<section>.

=head2 subsection

Optional menu subsection name.

The value will be automatically stashed under the key C<subsection>.

=cut

sub section { }
sub subsection { }

=head1 ACTIONS

=head2 begin

Stash L</section> and L</subsection> for use by templates

=cut

sub begin : Private {
    my ($self, $context) = @_;

    $context->stash->{section} = $self->section;
    $context->stash->{subsection} = $self->subsection;
}

=head2 mk_error

Takes a message to L<Carp/confess> with as the first argument and a message for
the error logs as the second.

=head2 mk_warn

Takes a message as the single argument.  Sends it to the error logs and sets up
an HTTP 400 response with the error message in the body, prefixed by C<Error:>.

=cut

sub mk_error : Private {
    my ($s,$c,$e1,$e2) = @_;
    $c->log->error("Error: $e2");
    confess($e1);
}

sub mk_warn : Private {
    my ($s,$c,$error) = @_;
    $c->log->error($error);
    $c->res->body("Error: $error");
    $c->response->status(400);
}

=head2 user_error

Takes a message for the response body as the first argument and sets up an HTTP
400 response.

The message is sent to the error logs, prefixed with C<User Error:>, if
debugging is on.  Any second argument is used for the log message in preference
to the first.

=cut

sub user_error : Private {
    my ($s,$c,$e1,$e2) = @_;
    $c->log->error("User Error: ".($e2||$e1)) if $c->debug;
    $c->response->body("Error: $e1");
    $c->response->status(400);
}

1;
