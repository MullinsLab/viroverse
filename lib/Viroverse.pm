=head1 NAME

Viroverse

=head1 DESCRIPTION

The main application class inheriting from L<Catalyst>.

This configures the application (plugins, caches, logging).

=cut

package Viroverse;

use strict;
use warnings;
use 5.018;

use Mail::Send;
use POSIX ();
use Viroverse::config;
use Carp ();
use Viroverse::Logger qw< :log >;

BEGIN {
    $Carp::Verbose = 1 if $Viroverse::config::debug;
}

#
# Set flags and add plugins for the application
#
#         -Debug: activates the debug mode for very useful log messages
#
use Catalyst qw/
    StackTrace

    Session
    Session::Store::FastMmap
    Session::State::Cookie
    Cache::FastMmap
    StatusMessage
/;

use CatalystX::RoleApplicator;
__PACKAGE__->apply_request_class_roles(qw/
    Catalyst::TraitFor::Request::ProxyBase
/);

our $VERSION = '0.01';

#
# Configure the application
#
__PACKAGE__->config( name => 'Viroverse',
    'View::TT' => {
        START_TAG      => '[\[<]%', # [% %] or <% %>
        END_TAG        => '%[\]>]',
        ENCODING       => 'UTF-8',
        'INCLUDE_PATH' => [
            __PACKAGE__->path_to('root/inputtemplate'),
            __PACKAGE__->path_to('root/browsetemplate'),
            __PACKAGE__->path_to('root/globaltemplate'),
            __PACKAGE__->path_to('root/searchtemplate'),
            __PACKAGE__->path_to('root/admintemplate'),
            __PACKAGE__->path_to('root/freezertemplate'),
        ],
        render_die => 1,
    },
    'View::NG' => {
        START_TAG      => '[\[<]%', # [% %] or <% %>
        END_TAG        => '%[\]>]',
        ENCODING       => 'UTF-8',
        INCLUDE_PATH => [
            __PACKAGE__->path_to('root/globaltemplate'),
            __PACKAGE__->path_to('root/ngtemplate')
        ]
    },
    'View::Vega' => {
        path => __PACKAGE__->path_to('root/vega')->stringify,
    },
 );

Viroverse->config->{'Plugin::Session'} = {
    page_size       => '256k',
    storage         => join("-", "/tmp/viroverse", $Viroverse::config::instance_name || $$),
    unlink_on_exit  => 0,
};

Viroverse->config->{cache}->{storage} = join("-", "/tmp/viroverse", "cache", $Viroverse::config::instance_name || $$);
Viroverse->config->{cache}->{unlink_on_exit} = 0;

Viroverse->config(
    # Don't find partial matches!
    disable_component_resolution_regex_fallback => 1,

    # Stop chain dispatch early if a link dies
    abort_chain_on_error_fix => 1,
);

# Setup logging
Viroverse->log( Viroverse::Logger->get_logger("Viroverse") );

#
# Start the application
#
__PACKAGE__->setup;

log_info { "Connected to database <$Viroverse::config::dsn>, debug=<$Viroverse::config::debug>" };

=head1 METHODS

=head2 debug

Delegates Catalyst's debug flag to C<Viroverse::config::debug>.

=head2 finalize_error

Send email on an error when not in debug mode.

=cut

sub debug { $Viroverse::config::debug }

sub finalize_error {
    my $c = shift;
    my @args = @_;

    if ($c->debug) {
        $c->next::method(@args);
    } else {

        #email errors that happen outside of debug (presumably unexpected)
        {
            local $SIG{CHLD} = 'DEFAULT';
            my $msg = Mail::Send->new;
            $msg->to($Viroverse::config::error_email);


            my $hn = $c->engine->env->{HTTP_X_FORWARDED_SERVER} || $c->engine->env->{SERVER_NAME} || `hostname`;
            chomp $hn;

            my $username = $c->req->remote_user;

            $msg->subject( "Viroverse died for $username on $hn at ".  POSIX::strftime('%F %H:%M:%S', localtime) );
            my $mfh = $msg->open;

            print $mfh join "\n", @{ $c->error };
            print $mfh "\n\n";

            print $mfh $c->req->method.": ".$c->req->uri."\n\n";

            print $mfh "Parameters:\n".Data::Dump::dump($c->req->params)."\n\n";

            print $mfh "Catalyst version: $Catalyst::VERSION \n\n";

        print $mfh "Parameters:\n".Data::Dump::dump($c->req->params)."\n\n";

        print $mfh "Environment:\n".Data::Dump::dump($c->engine->env)."\n\n";

        print $mfh "Catalyst version: $Catalyst::VERSION \n\n";
            print $mfh "Remote user: ", $c->req->remote_user, "\n\n";

            foreach my $thing ($c->dump_these) {
                next if $thing->[0] eq 'Request';
                next if $thing->[0] eq 'Response';
                next if $thing->[0] eq 'Config';
                print $mfh $thing->[0].":\n".Data::Dump::dump($thing->[1])."\n\n"; 
            }

            $mfh->close or log_error { "Failed to send error email: $!" };
        }

        $c->response->content_type('text/html; charset=utf-8');
        $c->response->body( $c->view('NG')->render($c, 'error.tt') );
        $c->response->status(500);
    }

}

1;
