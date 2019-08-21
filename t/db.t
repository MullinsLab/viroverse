use strict;
use Test::More;
use Test::Deep;

use Viroverse::db;
use Viroverse::config;
use Viroverse::session;
use Data::Dumper;

my $dbh;
my $session = Viroverse::session->new;

ok($dbh =  Viroverse::db::connect(Viroverse::Config->conf->{read_only_user},Viroverse::Config->conf->{read_only_pw}), 'database connect');

my ($test_sql, $custom_res, $dbi_res);


## selectrow_hr
$test_sql = q[SELECT na_SEQUENCE_id,scientist_id,sample_ID,ENTERED_DATE from viroserve.na_sequence where na_sequence_id = 1];
$custom_res = Viroverse::db::selectrow_hr($session,$test_sql);
$dbi_res    = $dbh->selectrow_hashref($test_sql);
cmp_deeply($custom_res, $dbi_res, 'selectrow_hr result values match dbi');


#resolve_external_property TODO: should actually use a non-literal value (first row or something) to test
ok( Viroverse::db::resolve_external_property($session,'scientist','Brandon Maust'), "two-param resolve_external_property" );
ok( Viroverse::db::resolve_external_property($session,'location','Seattle','city'), "three-param resolve_external_property");
ok( Viroverse::db::resolve_external_property($session,'location','seattle','city'), "three-param resolve_external_property, case insensitive");
is(
    Viroverse::db::resolve_external_property(
        $session,
        ['viroserve.location' => 'country_abbr'],
        'Seattle',
        'city'
    ),
    "US",
    "exact table/column resolve_external_property"
);

#mk_obj
ok( my $obj = Viroverse::db::mk_obj($session,$custom_res->{1}), 'mk_obj invocation');
is_deeply($session,$obj->{'session'}, 'mk_obj result has session');
cmp_ok((scalar keys %{$custom_res->{1}}) + 1, '==', scalar keys %$obj, 'mk_obj result length');

done_testing;
