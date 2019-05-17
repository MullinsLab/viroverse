use strict;
use warnings;
no warnings 'once';

use Test::More;

use_ok('Viroverse::config');

like (Viroverse::Config->conf->{error_email},qr/\w+@\w+\.\w+/,'valid email destination for errors');
like (Viroverse::Config->conf->{help_email},qr/\w+@\w+\.\w+/,'valid email destination for help requests');

ok (-x Viroverse::Config->conf->{quality},'quality can be run');
ok (-x Viroverse::Config->conf->{needle},'needle can be run');

ok (defined Viroverse::Config->conf->{template_defaults}->{max_results_json},'max_results_json set for stash');

done_testing;
