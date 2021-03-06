package Viroverse::db;
use strict;
use 5.010;
use utf8;

use Viroverse::Config;
use Viroverse::Logger qw< :log >;
use Carp qw[confess croak];

use DBI;
use POSIX ();

## Viroverse database access, bmaust June 2005
#  basic database connection methods
#  more interaction goes on in the session module where connections are initialized

my $dbh;

my $date_validate_traditional = qr[^[0-3]?[0-9]/[0-3]?[0-9]/(?:[0-9]{2})?[0-9]{2}$];
my $date_validate_iso = qr/^(?:[0-9]{2})?[0-9]{2}-[01]?[0-9]-[0-3]?[0-9]$/;

sub connect {
    my ($user,$pass) = @_ or die "need 2 arguments -- username and password";

    $dbh = DBI->connect(Viroverse::Config->conf->{dsn},$user,$pass) || confess("can't see db -- $DBI::errstr");

    $dbh->{ShowErrorStatement} = 1;

    return $dbh;

}

## get a db identifier from a vocabulary table, possibly adding it if allowed
#  assumes table name is same as property name and that primary key is table + _id
sub resolve_external_property { #($session, $property_name,$value)
    my ($session,$property,$value) = (shift, shift, shift) or croak "need a session, which property, and what value\n";
    my $column = (shift || 'name');
    my ($table, $select) = ref $property eq 'ARRAY'
        ? @$property
        : ("viroserve.$property" => "${property}_id");

    die "you gave me a $session instead of a Viroverse::session" unless $session->isa('Viroverse::session');

    my $id;
    for my $condition ("$column = ?", "LOWER($column) = LOWER(?)") {
        my $idh = $session->{'dbr'}->prepare_cached("SELECT $select FROM $table WHERE $condition");
        eval {
            $idh->execute($value);
        };
        croak "DB error: $@"
            if $@;

        $id = ($idh->fetchrow_array)[0];
        if ($id) {
            warn "Found more than one $property matching $condition <$value> using <$id>"
                if $idh->fetchrow_array;
            $idh->finish;
            last;
        }
        $idh->finish;
    }
    warn "Couldn't resolve $property $column <$value>"
        unless $id;

    return $id;
}

#takes a database row and returns hash-ified object for blessing
sub mk_obj {

    my ($session,$row) = (shift, shift);

    my $self = {};

    foreach my $key (keys %{$row}) {
        $self->{lc($key)} = $row->{$key};
    }

    $self->{'session'} = $session;

    return $self;
}

sub selectrow_hr {
    my ($session,@params) = @_;
    confess "illegal session" unless ref $session;

    my $res = $session->{'dbr'}->selectrow_hashref(@params);
    my %lc_results = map { (lc $_,$res->{$_}) } keys %$res ;
    return \%lc_results;
}

# XXX TODO: This should start using Viroverse::Date->parse_with_op()
sub validate_date {
    return 1 if $_[0] =~ m/$date_validate_traditional/;
    return 1 if $_[0] =~ m/$date_validate_iso/;

    return 0;
}

1;
