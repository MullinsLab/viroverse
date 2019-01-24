use strict;
use warnings;
use 5.018;

use Test::More;
use Test::Deep;
use Data::Dump qw< dump >;
use Viroverse::Model::alignment;

sub parse {
    my $alignment = shift;
    my @aln = split /\n/, $alignment =~ s/^\s+//gmr;
    Viroverse::Model::alignment->_parse_alignment_pairwise(@aln);
}

sub parse_ok {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my ($alignment, $ref, $query) = @_;
    my ($got, $expected);
    cmp_deeply(
        $got = [ parse($alignment) ],
        $expected = [
            [ map { [ split /-/ ] } @$ref   ],
            [ map { [ split /-/ ] } @$query ],
        ],
    ) or diag "   got : ", dump(@$got), "\n",
              "expect : ", dump(@$expected), "\n",
              " align :\n$alignment\n";
}

parse_ok(<<'',
    ATC-ATTCG
    ATCGA--CG

    [qw[ 1-3 3-3 4-4 5-6 7-8 ]],
    [qw[ 1-3 4-4 5-5 5-5 6-7 ]],
);

parse_ok(<<'',
    ATCGATCG
    --CGAT--

    [qw[ 3-6 ]],
    [qw[ 1-4 ]],
);

parse_ok(<<'',
    ATCG-TCG
    --CGAT--

    [qw[ 3-4 4-4 5-5 ]],
    [qw[ 1-2 3-3 4-4 ]],
);

parse_ok(<<'',
    AT-G-TCGATCG
    ATCGAT-G---G

    [qw[ 1-2 2-2 3-3 3-3 4-4 5-5 6-6 7-9 10-10 ]],
    [qw[ 1-2 3-3 4-4 5-5 6-6 6-6 7-7 7-7  8-8  ]],
);

# This should never happen with a real reference and query sequence...
parse_ok(<<'',
    ATCGATCG-
    --CGAT--A

    [qw[ 3-6 7-8 8-8 ]],
    [qw[ 1-4 4-4 5-5 ]],
);

# ...same with this
parse_ok(<<'',
    ATCGAT--
    --CGATCG

    [qw[ 3-6 6-6 ]],
    [qw[ 1-4 5-6 ]],
);

# ...and this
parse_ok(<<'',
    AT-G
    A-CG

    [qw[ 1-1 2-2 2-2 3-3 ]],
    [qw[ 1-1 1-1 2-2 3-3 ]],
);

ok !eval {
    parse_ok(<<'',
        ATCG-TCG
        --CG-T--A

    );
};
like $@, qr/unequal alignment lengths/i;

ok !eval {
    parse_ok(<<'',
        ATCG-TCG
        --CG-T--

    );
};
like $@, qr/gap in both/i;

done_testing;
