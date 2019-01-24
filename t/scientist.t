use strict;
use Test::More tests => 1;

use Viroverse::Model::scientist;
use Viroverse::session;
use Data::Dumper;

## list (is the only one used)
cmp_ok(Viroverse::Model::scientist->list(), '>', 0 , 'list() has at least 1 item');

