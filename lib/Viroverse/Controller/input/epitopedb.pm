package Viroverse::Controller::input::epitopedb;
use base 'Viroverse::Controller';

use strict;
use warnings;

use Catalyst::ResponseHelpers qw< :helpers :status >;

=head1 NAME

Viroverse::Controller::input::epitopedb - Wrapper for access to the other epitopedb actions

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=item begin
=cut

sub auto : Private {
    my ($self, $context) = @_;

    unless ($context->stash->{features}->{epitopedb}) {
        return NotFound($context, "Feature disabled: EpitopeDB");
    }

    return Forbidden($context)
        unless $context->stash->{scientist}->can_edit;
}

1;
