use 5.018;
use strict;
use warnings;
use utf8;

package Viroverse::API::Resource;

use Moo;
use Types::Standard qw< InstanceOf >;
use JSON::MaybeXS;
use namespace::clean;

extends 'Web::Machine::Resource';

has current_scientist => (
    is  => 'lazy',
    isa => InstanceOf['ViroDB::Result::Scientist'],
);

has serializer => (
    is      => 'ro',
    default => sub { JSON::MaybeXS->new->utf8->convert_blessed },
);

sub _build_current_scientist {
    $_[0]->request->env->{"viroverse.scientist"}
}

sub base_uri {
    $_[0]->request->base
}

sub error_as_json {
    my ($self, $return) = @_;
    $self->response->status( $$return );
    $self->response->header( "Content-type" => "application/json; charset=utf-8" );
    $self->response->body( $self->serializer->encode({ message => join "", @_ }) );
    return $return;
}

sub charsets_provided { [ 'utf-8' ] }
sub default_charset   {   'utf-8'   }

sub content_types_provided { [
    { 'application/json' => 'to_json' },
] }

sub to_json {
    my $self = shift;
    return $self->serializer->encode($self->to_data);
}

sub to_data {
    die "to_data() must be implemented by a subclass (called on ", ref($_[0]), ")";
}

1;
