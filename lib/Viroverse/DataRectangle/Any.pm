use 5.018;
use utf8;
use warnings;
use strict;

package Viroverse::DataRectangle::Any;
use Moo;
use Module::Pluggable::Object;
use Carp qw< confess >;
use List::Util qw< first any >;
use Types::Standard -types;
use namespace::clean;

=head1 NAME

Viroverse::DataRectangle::Any

=head1 SYNOPSIS

    my $d1 = Viroverse::DataRectangle::Any->new(file => "path/to/file.xls");
    my $d2 = Viroverse::DataRectangle::Any->new(
        file           => "var/storage/a/bc/def0123456789",
        file_extension => "csv",
    );

=head1 DESCRIPTION

A L<Viroverse::DataRectangle> class that identifies the appropriate
implementation for the provided file based on its extension.

=head1 ATTRIBUTES

See L<Viroverse::DataRectangle/ATTRIBUTES> for the complete interface.

=cut

sub extensions {
    my $pkg = shift;
    die "You can't check extensions for $pkg";
}

has _implementation => (
    is  => 'lazy',
    isa => ConsumerOf['Viroverse::DataRectangle'],
);

with 'Viroverse::DataRectangle';

sub _build__implementation {
    my $self = shift;
    my $xt = $self->file_extension;

    state $handlers = [
        sort
        grep { $_ ne ref $self }
        Module::Pluggable::Object->new(
            search_path      => "Viroverse::DataRectangle",
            require          => 1,
            on_require_error => sub {
                confess "Couldn't require $_[0]: $_[1]";
            },
        )->plugins
    ];

    my $handler = first { any { $_ eq $xt } $_->extensions } @$handlers;
    die "No DataRectangle handler found for extension $xt" unless $handler;
    return $handler->new(file => $self->file, file_extension => $xt);
}

sub _build_header { $_[0]->_implementation->header }

sub _build_rows { $_[0]->_implementation->rows }

1;
