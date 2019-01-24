use strict;
use warnings;
use Test::More;
use Test::Warnings 0.005 ':all';
use Viroverse::CDBI;
use Viroverse::Test { no_web => 1 };

Viroverse::CDBI->db_Main->do("CREATE TEMPORARY TABLE txn_test (test_id text)");
package TxnTest {
    use base 'Viroverse::CDBI';
    __PACKAGE__->table('txn_test');
    __PACKAGE__->columns( All => qw[ test_id ]);
}

# Out of scope without commit
{
    my $test_id = sprintf "%s#%d@%d", __FILE__, __LINE__, time;
    like(
        warning {
            my $txn = Viroverse::CDBI->txn_scope_guard;
            TxnTest->insert({ test_id => $test_id });
        },
        qr/Rolling back transaction/,
        "rollback warning"
    );
    ok !TxnTest->retrieve($test_id), "No TxnTest created";
}

# Out of scope via error
{
    my $test_id = sprintf "%s#%d@%d", __FILE__, __LINE__, time;
    like(
        warning {
            eval {
                my $txn = Viroverse::CDBI->txn_scope_guard;
                TxnTest->insert({ test_id => $test_id });
                die "boom";
            };
        },
        qr/Rolling back transaction/,
        "rollback warning"
    );
    ok !TxnTest->retrieve($test_id), "No TxnTest created";
}

# Explicit rollback
{
    my $test_id = sprintf "%s#%d@%d", __FILE__, __LINE__, time;
    {
        my $txn = Viroverse::CDBI->txn_scope_guard;
        TxnTest->insert({ test_id => $test_id });
        $txn->rollback;
    }
    ok !TxnTest->retrieve($test_id), "No TxnTest created";
}

# Explicit commit
{
    my $test_id = sprintf "%s#%d@%d", __FILE__, __LINE__, time;
    {
        my $txn = Viroverse::CDBI->txn_scope_guard;
        TxnTest->insert({ test_id => $test_id });
        $txn->commit;
    }
    ok my $sci = TxnTest->retrieve($test_id), "TxnTest created";
}

done_testing;
