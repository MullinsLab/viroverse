use strict;
use warnings;
use 5.018;
use Test::More;

my $flex_loggers = <<"";
$^X -MViroverse::Logger=-script,:log -E '
    log_debug { "debug" };
    log_info  { "info" };
    log_warn  { "warn" };
    log_error { "error" };
' 2>&1

for my $quiet (1, 0) {
    for my $debug (0, 1) {
        my $vars   = "VVQUIET=$quiet VVDEBUG=$debug";
        my $output = `env $vars $flex_loggers`;

        my @all      = qw(debug info warn error);
        my @expected = qw(warn error);
        push @expected, 'info' unless $quiet;
        push @expected, 'debug' if $debug and not $quiet;
        subtest $vars => sub {
            like $output, qr/\Q$_\E/, $_
                for @expected;

            my %expected = map { $_ => 1 } @expected;
            unlike $output, qr/\Q$_\E/, "omits $_"
                for grep { not $expected{$_} } @all;
        };
    }
}

done_testing;
