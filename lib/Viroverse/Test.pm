use strict;
use warnings;
use 5.018;

BEGIN {
    use Viroverse::config;
    $Viroverse::config::debug = 0;
    $Viroverse::config::dsn =~ s/(?<=dbname=)([^;]+)/${1}_test/;
}

package Viroverse::Test;

use Test::More;
use File::Basename qw< dirname >;
use Plack::Util;
use namespace::clean;

BEGIN {
    $ENV{CATALYST_HOME} = dirname($INC{'Viroverse/Test.pm'}) . "/../../";
    $ENV{REMOTE_USER}   = "vverse";

    $ENV{VIROVERSE_LOG_LEVEL} ||= "warn";
}

use base 'Exporter::Tiny';
our @EXPORT = qw( request_ok );
our $APP;

sub _exporter_validate_opts {
    my ($class, $opts) = @_;
    $APP = Plack::Util::load_psgi("$ENV{CATALYST_HOME}/app.psgi")
        unless delete $opts->{no_web};
}

require Catalyst::Test;
require Viroverse;

=head1 NAME

Viroverse::Test - Utility class for testing Viroverse

=head1 SYNOPSIS

    use Viroverse::Test;
    use Viroverse::Test { no_web => 1 };

=head1 DESCRIPTION

Viroverse::Test starts the application (via F<app.psgi>) and exports functions
into your namespace.  Viroverse::Test is an L<Exporter::Tiny>, so features
provided by that may be used.

The C<no_web> global export option may be passed to disable loading of the web
application.  The test database will still be available.

=cut

=head1 EXPORTS

=head2 request_ok

Operates just like L<Catalyst::Test/request>, but takes an optional second
parameter for a test description and tests that the L<HTTP::Response> return
status is 200, or 304 if the request involved an C<If-Modified-Since> header.

Returns the L<HTTP::Response> object.

=cut

sub request_ok {
    my ($req, $desc) = @_;
    $desc ||= join " ", $req->method, $req->uri;

    my $res = _request($req);

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    ok($res->is_success || ($req->header('If-Modified-Since') ? $res->code == 304 : 0), $desc)
        or diag "Failed request: ", $res->status_line, " with body ", explain $res->decoded_content;

    return $res;
}

sub _request {
    my $req = shift;
    die "No app loaded!  Was this a no_web import?" unless $APP;
    Catalyst::Test::_local_request( $APP, $req, @_ );
}

1;
