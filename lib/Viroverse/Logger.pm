use strict;
use warnings;
use 5.018;

package Viroverse::Logger;
use Moo;
use FindBin qw< $Script >;
use Import::Into;
use Log::Contextual qw< set_logger >;
use Log::Log4perl;
use Log::Log4perl::Level qw<>;
use String::Flogger qw< flog >;
use Types::Standard qw< :types >;
use Viroverse::Config;
use namespace::clean;

=head1 NAME

Viroverse::Logger - base logging system for Viroverse's CLI and web server components

=head1 SYNOPSIS

    use Viroverse::Logger qw< :log >;

    log_info { "A day in the park would be grand!" };
    log_debug {[ "I'd like a slice of that blueberry %0.2f, please.", 3.14159 ]};

    # Supported levels are trace, debug, info, warn, error, and fatal

=head1 DESCRIPTION

Viroverse::Logger manages a collection of per-component loggers and exports
logging functions from the wonderful L<Log::Contextual>.  Messages are passed
through L<String::Flogger> for easy formatting (such as in the C<log_debug>
example above).

Configuration is primarily done through F<logger.conf>, or the file pointed to
by the C<LOG4PERL_CONFIG> environment variable.

=cut

# Initialize Log4perl
Log::Log4perl->init_once( $ENV{LOG4PERL_CONFIG} || "$ENV{VIROVERSE_ROOT}/logger.conf" );
Log::Log4perl->wrapper_register( __PACKAGE__ );

Log::Log4perl->get_logger("")->level('DEBUG')
    if Viroverse::Config->conf->{debug};

Log::Log4perl->get_logger("")->level(uc $ENV{VIROVERSE_LOG_LEVEL})
    if $ENV{VIROVERSE_LOG_LEVEL};


# Initialize Log::Contextual
my %PACKAGE_TO_COMPONENT;

set_logger sub {
    my ($caller_package, $info) = @_;
    return __PACKAGE__->get_logger(
           $PACKAGE_TO_COMPONENT{$caller_package}
        // $caller_package
    );
};


=head1 IMPORT OPTIONS

Any L<Log::Contextual> exports may be requested during import, including the
two most useful groups: C<:log> and C<:dlog>.

Additionally, this module has two special options provided at import time:

=head2 C<-component>

The C<-component> option takes a value which is used as the preferred name for
the current package in log messages.  Typically you'd set this only if the
package name isn't suitable for some reason (for example, inside F<app.psgi>).
Component names are used to adjust logging for just that component via the
configuration file.

=head2 C<-script>

The C<-script> option is a flag which sets the current package's component name
to L<FindBin>'s C<$Script>.  The two stanzas below are equivalent:

    use Viroverse::Logger -script => qw< :log >;

    use FindBin qw< $Script >;
    use Viroverse::Logger -component => $Script, qw< :log >;

=cut

sub import {
    my $self   = shift;
    my $caller = scalar caller;
    my @imports;

    while (@_) {
        my $arg = shift @_;
        if ($arg eq '-script') {
            $PACKAGE_TO_COMPONENT{$caller} = $Script;
        } elsif ($arg eq '-component') {
            $PACKAGE_TO_COMPONENT{$caller} = shift @_;
        } else {
            push @imports, $arg;
        }
    }

    STDERR->autoflush(1);   # XXX TODO: Move this out of import?
    Log::Contextual->import::into($caller, @imports) if @imports;
}


=head1 CLASS METHODS

=head2 get_logger

Takes a component name (such as a package name) and returns a logger object
which conforms to L<Log::Contextual>'s minimal interface.  You should only use
this if you need to provide a logger object to some other system.  If you only
need to log messages yourself, use the L<Log::Contextual> functions.

If no component name is provided, the root logger object is returned.  (Note
that this is different than L<Log::Log4perl/get_logger>.)

=cut

sub get_logger {
    my $class     = shift;
    my $component = shift // "";
    return __PACKAGE__->new( _logger => Log::Log4perl->get_logger($component) );
}


=head2 psgi_logger

Returns a coderef implementing the C<psgix.logger> interface.

=cut

sub psgi_logger {
    my $class = shift;
    return sub {
        my $args = shift;
        return $class->get_logger("psgi")->log(
            $args->{level},
            $args->{message}
        );
    };
}


=head2 add_global_appender

Takes a supported appender package name as the first argument (such as a
L<Log::Dispatch> or L<Log::Log4perl> appender) and adds it to the root logger.
Additional arguments are passed to the appender's constructor.

Note that since our loggers are singletons which are persistent per-process,
you should only call this method once per-process for each appender you want to
add.

This method is designed as a mechanism for code to hook into the logging
system and capture messages.

=cut

sub add_global_appender {
    my $class    = shift;
    my $appender = shift;
    Log::Log4perl->get_logger("")->add_appender(
        Log::Log4perl::Appender->new($appender, @_)
    );
}

=head2 add_temp_appender

Takes the same arguments as L</add_global_appender> and returns a sentinel
that removes the appender from the root logger when the sentinel goes out
of scope.

=cut

package ScopeSentinel {
    use Moo;
    use Types::Standard qw< :types >;

    has appender_name => (
        is  => 'ro',
        isa => Str,
    );

    has logger => (
        is => 'ro',
        isa => InstanceOf['Log::Log4perl::Logger'],
    );

    has _done => (
        is => 'rwp',
        isa => Bool,
    );

    sub DEMOLISH {
        my $self = shift;
        return if $self->_done;
        $self->done;
    }

    sub done {
        my $self = shift;
        return if $self->_done;
        $self->logger->eradicate_appender($self->appender_name);
        $self->_set__done(1);
    }
}

sub add_temp_appender {
    my $class = shift;
    my $appender_class = shift;
    my $logger = Log::Log4perl->get_logger("");
    my $appender = Log::Log4perl::Appender->new(
        $appender_class,
        @_
    );

    $logger->add_appender($appender);

    return ScopeSentinel->new(appender_name => $appender->name, logger => $logger)

}

# This class can also be an object which proxies to a Log4perl logger after
# transforming messages with String::Flogger.  It implements the minimal
# interface required by Log::Contextual.  Defining our own class with all these
# methods is easier than using a custom subclass of Log::Log4perl::Logger due
# to its design.
#
# You shouldn't create your own instances of this class!
# Always fetch them via L</get_logger>.

has _logger => (
    is       => 'ro',
    isa      => InstanceOf['Log::Log4perl::Logger'],
    required => 1,
    handles  => [qw[
        is_trace
        is_debug
        is_info
        is_warn
        is_error
        is_fatal
    ]],
);

sub trace { $_[0]->log('trace', @_[1..$#_]) }
sub debug { $_[0]->log('debug', @_[1..$#_]) }
sub info  { $_[0]->log('info',  @_[1..$#_]) }
sub warn  { $_[0]->log('warn',  @_[1..$#_]) }
sub error { $_[0]->log('error', @_[1..$#_]) }
sub fatal { $_[0]->log('fatal', @_[1..$#_]) }
sub log {
    my ($self, $level, @messages) = @_;

    # log('fatal', …) won't die and logcroak doesn't take a priority
    my $log = lc $level eq 'fatal'
        ? sub { $self->_logger->logcroak(@_[1..$#_]) }
        : sub { $self->_logger->log(@_) };

    return $log->(
        Log::Log4perl::Level::to_priority(uc $level),
        map { chomp; $_ } map { flog($_) } @messages
    );
}

1;
