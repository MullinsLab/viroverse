use 5.010;
use warnings;
use strict;
use Test::More;
use List::Util qw< pairs >;
use Path::Tiny;

use ViroDB::Result::Chromat;

my $re = ViroDB::Result::Chromat->plausible_primer_regex;

sub aok { my ($a, $b) = @_; my ($r) = $a =~ $re; is($r, $b, "$a should give $b"); }

my @tests = (
    "A-B.ab1"                                           => "B",
    'NDRI112_KiD_V1V5_TaBaE15-RV_F58~36a!$@#.$@#1F.ab1' => 'F58~36a!$@#.$@#1F',
    'this_is_a_name-this_is_bogus-this_is_a_primer.SCF' => 'primer',
    'NDRI112_KiD_5pol_TaBaP14-SQ13R.ab1'                => 'SQ13R',
    '10310970_04.11.06_E19-R6566.ab1'                   => 'R6566',
    'OXM57-GP120-5.ab1'                                 => 'GP120-5',
    '106500836_WG5-R7455.SCF'                           => 'R7455',
    '50331186_051011_E30-gp120_5.SCF'                   => 'gp120_5',
    'NNAB1139_SID_5pol_CaHiP09-PR4.ab1'                 => 'PR4',
    'AA026_6-AE20F.ab1'                                 => 'AE20F',
    '165500037_LH2-R2126.SCF'                           => 'R2126',
    '194-5-0004-9LH9_SQ15R.SCF'                         => 'SQ15R',
    'NFJ109-SQ15FA(2).ab1'                              => 'SQ15FA(2)',

    # From Kim, 15 Jan 2016
    'SIV_14043_GAG31-NL5RT-F.SCF'                       => 'NL5RT-F',

    # From Katie
    '1626RH2-SQ15F.scf.ab1'                              => 'SQ15F',
    '1626RH01-AE9R.ab1 (reversed).ab1'                   => 'AE9R',
    '1626_01-24-15_RH13-235SALPL-DEG.ab1 (reversed).ab1' => "235SALPL-DEG",

    # From Lennie, sequenced by MCLab
    '1796_279-B1_LH1_SQ10R_E11.SCF'                     => 'SQ10R',
    '1796_279-B1_LH1_TATB_alt2_C11.SCF'                 => 'TATB_alt2',

    # more from the corpus
    # this example is known to only extract part of the primer name.
    # The database query side of this has been revised to do a
    # substring match instead of a prefix match against primer names.
    'SIV_14046_RH03-R_LTRr602.SCF'                      => 'LTRr602',

    'NDRI112_LID_MEnv2_NDRI112EnvCpGI_F2_E10.ab1'       => 'NDRI112EnvCpGI_F2',

    # From Kim, March 2017
    # Extant version only matched 'M' from each of these
    'P277-MozFo_M.SCF'                                  => 'MozFo_M',
    'P277-lbr2_M.SCF'                                   => 'lbr2_M',

);

aok(@$_)
    for pairs @tests;

# Report on how well our primer regex works to extract a primer name if it's
# present in the filename exactly as-is.
#
# t/primers.txt was generated with:
#   psql -qAt -h ireland -U viroverse_r viroverse <<<"select name from viroserve.primer order by lower(name);" > t/primers.txt
{
    my @primers = path(__FILE__)->parent->child("primers.txt")->lines_utf8({ chomp => 1 });
    my (@ok, @partial, @fail);

    for my $primer (@primers) {
        my ($extracted) = "$primer.scf" =~ $re;
        if (not $extracted) {
            push @fail, $primer;
        } elsif ($extracted eq $primer) {
            push @ok, $primer;
        } else {
            push @partial, $primer
                =~ s/\Q$extracted\E/.../r
                =~ s/\d+/<n>/gr;
        }
    }
    my %partial;
    $partial{$_}++ for @partial;

    note "=====================================================";
    note "Testing primer extraction regex against t/primers.txt";
    note "=====================================================";
    note sprintf "%4d primers matched completely", scalar @ok;
    note sprintf "%4d primers matched partially", scalar @partial;
    note sprintf "%4d primers didn't match:", scalar @fail;
    note sprintf "     %s", $_ for @fail;
    note "Common partially matched names:";
    note sprintf "%4d %s", @$_[1,0]
        for sort { $a->[0] cmp $b->[0] or $b->[1] <=> $a->[1] }
            grep { $_->[1] > 1 }
            pairs %partial;
}

done_testing;
