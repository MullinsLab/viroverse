package Plack::Middleware::Debug::ViroverseLogger;

use strict;
use warnings;
use utf8;
use 5.010;

use parent qw(Plack::Middleware::Debug::Base);
use Viroverse::Logger;
use Log::Dispatch::Code;
use HTML::Entities qw< encode_entities >;

my @output;

Viroverse::Logger->add_global_appender(
    "Log::Dispatch::Code",
    code => sub {
        my %args = @_;
        my $msg = $args{message};
        push @output, $msg;
    }
);

sub run {
    my ($self, $env, $panel) = @_;

    # Clear output before every request
    @output = ();

    sub {
        my $res   = shift;
        my $lines = join "", map { encode_entities($_) } @output;
        $panel->content("<pre>\n\n$lines\n\n</pre>");
    }
}

1;
