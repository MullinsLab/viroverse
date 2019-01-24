BEGIN {
    # Setup app lib paths
    require lib;
    require File::Spec;
    my $base = (File::Spec->splitpath(
        File::Spec->rel2abs( readlink(__FILE__) || __FILE__ )))[1];
    $base =~ s/\/$//;
    lib->import( "$base/lib", );

    # Setup Catalyst; it really wants the chdir()
    chdir $base
        or warn "Couldn't chdir to $base: $!";
    $ENV{CATALYST_HOME} = $base;

    # Setup %ENV
    $ENV{PATH} = '/sbin:/usr/sbin:/bin:/usr/local/bin:/usr/bin';
}

use Plack::Builder;
use Plack::App::File;
use Viroverse::Logger -component => "app.psgi", qw< :log >;

use Viroverse;
my $app = Viroverse->psgi_app;


builder {
    # Provide a logger for PSGI components to use
    enable sub {
        my $app = shift;
        return sub {
            my $env = shift;
            $env->{'psgix.logger'} = Viroverse::Logger->psgi_logger;
            return $app->($env);
        };
    };

    enable "NoMultipleSlashes";

    # We use resources which vary responses based on the request's Accept:
    # header, so caching agents must use Accept: as a cache key.  See also the
    # Chrome back button behaviour which uncovered our need for Vary:
    # https://code.google.com/p/chromium/issues/detail?id=94369
    enable 'Header',
        append => [ Vary => 'Accept' ];

    if (($ENV{PLACK_ENV} || '') eq 'development') {
        my $user = $ENV{REMOTE_USER} || $ENV{USER} || `whoami`;
        chomp $user;
        log_warn { "Forcing REMOTE_USER to '$user'" };
        enable "ForceEnv", REMOTE_USER => $user;

        if (Viroverse->debug) {
            enable "Debug", panels => [];
            enable "Debug::DBIC::QueryLog";
            enable "Debug::DBITrace",   level   => "SQL";
            enable "Debug::DBIProfile", profile => "!Statement";
            enable "Debug::Timer";
            enable "Debug::Environment";
            enable "Debug::CatalystStash";
            enable "Debug::ViroverseLogger";
        }
    }

    mount "/static" => builder {
        enable "ConditionalGET";
        Plack::App::File->new( root => "$ENV{CATALYST_HOME}/root/static/" );
    };
    mount "/" => $app;
}
