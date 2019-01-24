use strict;
use warnings;
package Viroverse::Worker::Align::Needle;
use Moo;
use Viroverse::Logger qw< :log >;
use namespace::clean;

with 'Viroverse::Worker::Cron';

# On eval, each worker is about 53MB and needle grows to a max of about 1.3GB.

# Minimum 5 min process life time
# Maximum lifetime is minimum + RESERVE_TIMEOUT + 1-60 seconds jitter (below)
use constant LIFETIME    => 5 * 60;
use constant MAX_WORKERS => 2;
use constant RESERVE_TIMEOUT    => 10; # Block waiting for a job for up to 10s
use constant MAIN_LOCK_INTERVAL => 5;  # Attempt to get main lock every 5s

use constant TUBE => 'align/needle';

use Viroverse::Model::alignment;

sub run_job {
    my $self = shift;
    my $job  = shift or die "No job";
    my $data = $job->args;
    my $retry = 0;
    my $query = 0;

    # Sequences may not yet be visible to our transaction,
    # retry briefly with exponential backoff.
    while ((not $query) && ($retry < 3)) {
        sleep 2**++$retry;
        log_debug{[ "Looking for DNA...%d", $retry ]}
        $query = Viroverse::Model::sequence::dna->retrieve($data->{query_id});
    }
    if (not $query) {
        log_error {[ "Cannot retrieve sequence #%s", $data->{query_id} ]};
        return;
    }

    if (my $aln = $query->hxb2_aln) {
        log_info {[ "Skipping sequence #%s: already needle aligned (alignment #%s)", $query->idrev, $aln->id ]};
        return;
    }

    my $aligned = Viroverse::Model::alignment->needle_align(
        $data->{reference_id},
        $data->{query_id},
        { store => 1 }
    ) or die "Failed to create an alignment";

    log_debug {[ "Created alignment #%s", $aligned->idrev ]};
}

1;
