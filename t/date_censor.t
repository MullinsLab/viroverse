use 5.010;
use warnings;
use strict;
use ViroDB;
use Test::More;
use Viroverse::DateCensor;
use namespace::clean;


sub ymd {
    my ($y, $m, $d) = @_;
    return DateTime->new(year => $y, month => $m, day => $d);
}

my $y2k = ymd(2000, 1, 1);

sub test {
    my ($date, $do_censor, $repr, $expect) = @_;
    my $censor = Viroverse::DateCensor->new(
        censor         => $do_censor,
        relative_unit  => $repr,
        reference_date => $y2k,
    );
    is($censor->represent_date($date), $expect,
        sprintf "%s as %s should be %s when %s",
                $date->strftime("%Y-%m-%d"),
                $repr,
                $expect,
                $do_censor ? 'censored' : 'not_censored');
}

test(ymd(2000,1, 2), 1, 'days',   '1d');
test(ymd(2001,1, 1), 1, 'years',  '1.0y');
test(ymd(2001,1, 1), 1, 'weeks',  '51w'); #NB
test(ymd(2001,1, 8), 1, 'weeks',  '52w'); #NB
test(ymd(2001,1, 1), 1, 'months', '12.0m');
test(ymd(2008,7, 1), 1, 'years',  '8.4y'); #NB
test(ymd(2008,7, 1), 1, 'months', '102.0m');
test(ymd(2001,1, 1), 0, 'years',  '2001-01-01');

done_testing;

