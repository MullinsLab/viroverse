use strict;
use warnings;
use utf8;
use 5.018;

package Viroverse::Sparkline;
use Moo;
use SVG::Sparkline;
use Try::Tiny;
use Types::Standard qw< :types >;
use Viroverse::Logger qw< :dlog >;
use namespace::clean;

has height => ( is => 'ro', isa => Int, default =>  20 );
has width  => ( is => 'ro', isa => Int, default => 120 );
has color  => ( is => 'ro', isa => Str, default => 'red' );

sub xy_sparkline {
    my $self   = shift;
    my $xy_pts = shift
        or return "";

    my $svg = try {
        SVG::Sparkline->new(
            Line => {
                values => $xy_pts,
                height => $self->height,
                width  => $self->width,
                color  => $self->color,
                mark   => [ high => 'blue', low => 'black' ],
                padx   => 2,
                pady   => 2,
            }
        )->to_string;
    } catch {
        my $err = $_;
        Dlog_error { "Broken sparkline: $_" } $err;
        return "";
    };
    return $svg;
}

1;
