use strict;
use warnings;
use utf8;
use 5.018;

=encoding UTF-8

=head1 NAME

Viroverse::Logger::Capture - Captures structured log messages into an array

=head1 SYNOPSIS

    my $log   = [];
    my $guard = Viroverse::Logger->add_temporary_appender(
        "Viroverse::Logger::Capture",
        array => $log,
    );
    
    # … log some stuff …
    
    $guard->done;
    say Dumper($_) for @$log;

=head1 DESCRIPTION

This appender is just like L<Log::Dispatch::Array>, except it pushes simplified
and normalized data structures onto your array instead of the raw data the
logging framework is pushing through the appender.  Note that this appender is
only intended to work with L<Log::Log4perl> as it relies on log data added by
L<Log::Log4perl::Appender>.

Each log message will be represented like the following:

    {
        level    => "WARN",
        message  => "Beware the jabberwock, my son\n",
        category => "Through.The.Looking.Glass",
    }

=cut

package Viroverse::Logger::Capture;
use parent 'Log::Dispatch::Array';

sub log_message {
    my ($self, %p) = @_;
    push @{ $self->array }, {
        level    => $p{log4p_level},
        message  => $p{message},
        category => $p{log4p_category},
    };
}

1;
