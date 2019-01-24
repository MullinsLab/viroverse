package Viroverse::session;
use strict;
use Viroverse::db;
use Viroverse::config;

use Digest::MD5 qw(md5_base64);
use Time::HiRes;
use Carp qw[croak carp];

## Session.pm -- Viroverse session management, bmaust June 2005
#  The session stores information about a user's session with the viroverse
#  that doesn't need to persist beyond a browser session such as:
#  authentication and authorization details, db connection info.
#  Each session is associated with state information, which is how more
#  long-term user values are actually stored in the db.

sub new {
    my ($class, $dbh) = @_;
    my $self = {};
    bless $self, $class;

    $self->{'id'} = Digest::MD5::md5_base64(Time::HiRes::time()+rand);
    if ($dbh) {
        $self->{'dbr'} = $dbh;
        $self->{'dbw'} = $dbh;
    } else {
        $self->{'dbr'} = Viroverse::db::connect($Viroverse::config::read_only_user,$Viroverse::config::read_only_pw);
        $self->{'dbw'} = Viroverse::db::connect($Viroverse::config::read_write_user,$Viroverse::config::read_write_pw);
        $self->{'dbw'}->{'RaiseError'} = 1;
        $self->{'dbw'}->{'LongReadLen'} = 10000;
        $self->{'dbr'}->{'LongReadLen'} = 10000;
        $self->{'dbr'}->{'RaiseError'} = 1;
    }

    return $self;
}

1;
