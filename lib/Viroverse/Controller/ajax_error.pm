package Viroverse::Controller::ajax_error;
use base 'Viroverse::Controller';

use strict;
use warnings;

=head1 NAME

Viroverse::Controller::ajax_error

=head1 DESCRIPTION

Catalyst Controller to handle not fatal errors from AJAX requests and pass meaningfull information back to the user

=cut

sub make_error : Private {
    my ($self, $c) = @_;
    my $msg = $c->req->args->[0];

   $c->response->{body} = qq[{"error" : { "msg" : "$msg"}}];
}

1;

