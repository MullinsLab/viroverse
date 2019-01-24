use strict;
use Test::More;
use Scalar::Util qw< refaddr >;

use Viroverse::session;
use Data::Dumper;

my $session = Viroverse::session->new;

use_ok('Viroverse::sample');

cmp_ok( Viroverse::sample->list_tissue_types($session),
            '>', 0,
            'list_tissue_types()');

done_testing;
