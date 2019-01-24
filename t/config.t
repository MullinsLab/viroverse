use strict;
use warnings;
no warnings 'once';

use Test::More;

use_ok('Viroverse::config');

like ($Viroverse::config::error_email,qr/\w+@\w+\.\w+/,'valid email destination for errors');
like ($Viroverse::config::help_email,qr/\w+@\w+\.\w+/,'valid email destination for help requests');

ok (-x $Viroverse::config::quality,'quality can be run');
ok (-x $Viroverse::config::needle,'needle can be run');

ok (defined $Viroverse::config::max_results_json,'max_results_json set');
ok (defined $Viroverse::config::template_defaults->{max_results_json},'max_results_json set for stash');

done_testing;
