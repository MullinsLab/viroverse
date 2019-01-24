use strict;
use warnings;
use 5.018;

package Viroverse::Controller::API;
use base 'Viroverse::Controller';

use Catalyst::Action::FromPSGI;

use Web::Machine;

use Module::Runtime qw< require_module >;
use namespace::autoclean;

sub base : Chained PathPart('api') CaptureArgs(0) { }

sub sequence : Chained('base') PathPart('sequence') Args ActionClass('FromPSGI') {
    my ($self, $c) = @_;
    $self->webmachine("Sequence");
}

sub webmachine {
    state $cache = {};

    my ($self, $class, $args) = @_;
    $class = "Viroverse::API::Resource::$class";
    require_module($class);
    $cache->{$class} ||= Web::Machine->new(
        resource        => $class,
        resource_args   => $args,
    );
}

1;

