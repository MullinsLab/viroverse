use strict;
use warnings;
use utf8;
use Test::More;
use Viroverse::SQL::Library;

my $library = Viroverse::SQL::Library->new;

{
    my $sql = $library->pcr_ancestors( pcrs => [1, 1, 2, 3, 5, 8] );
    ok     $sql,                           "Got SQL";
    like   $sql, qr/\Q?, ?, ?, ?, ?, ?\E/, "Found 6 placeholders";
    unlike $sql, qr/gel_lane/,             "No mention of gel_lanes";
}

{
    my $sql = $library->pcr_ancestors( gel_lanes => [1, 1, 2, 3, 5, 8] );
    ok     $sql,                                 "Got SQL";
    like   $sql, qr/\Q?, ?, ?, ?, ?, ?\E/,       "Found 6 placeholders";
    like   $sql, qr/JOIN\s*viroserve\.gel_lane/, "Found gel_lane JOIN";
    unlike $sql, qr/pcr_product_id\s*IN/,        "No mention of pcr_product_id condition";
}

done_testing;
