use 5.018;
use strict;
use warnings;
package Viroverse::Worker::Cron;

# Based on example from "Writing Advanced Daemons That Aren't Daemons",
# http://blog.booking.com/non-daemons-advanced-daemons-that-arent-daemons.html
use IPC::ConcurrencyLimit::WithStandby;
use FindBin qw< $RealBin >;
use Try::Tiny;
use Beanstalk::Client;
use Viroverse::Logger qw< :log >;
use Moo::Role;
use namespace::clean;

use constant RUN_DIR => "$RealBin/../var/run";

requires 'LIFETIME';
requires 'MAX_WORKERS';
requires 'RESERVE_TIMEOUT';
requires 'MAIN_LOCK_INTERVAL';
requires 'TUBE';

requires 'run_job';

sub run {
    my $self  = shift;
    my $class = ref($self) || $self;
    my $type  = $class =~ s/^Viroverse::Worker:://r;
    my $limit = IPC::ConcurrencyLimit::WithStandby->new(
        type                => 'Flock',
        path                => RUN_DIR . "/$type",
        max_procs           => $self->MAX_WORKERS,
        standby_path        => RUN_DIR . "/$type-standby",
        standby_max_procs   => $self->MAX_WORKERS,
        interval            => $self->MAIN_LOCK_INTERVAL,

        # Keep retrying for ~3x lifetime of the worker process
        retries             => 1 + 3*int($self->LIFETIME / $self->MAIN_LOCK_INTERVAL),
        process_name_change => 1,
    );

    log_debug { "Standing by to get lock" };
    my $lock_id = $limit->get_lock;
    if (not $limit->get_lock) {
        log_debug { "Exiting after failing to get main lock" };
        exit 0;
    }
    else {
        my $end_time = time + $self->LIFETIME + int rand 60; # jitter up to 1m

        my $queue = Beanstalk::Client->new;
        $queue->watch_only($self->TUBE);
        log_debug { "Watching tube ", $self->TUBE };

        while (1) {
            if ( my $job = $queue->reserve($self->RESERVE_TIMEOUT) ) {
                try {
                    log_debug {[ "Running %s job #%d", $job->tube, $job->id ]};
                    $self->run_job($job);
                    $job->delete or die "Couldn't delete job: ", $queue->error;
                } catch {
                    log_warn {[ "Burying %s job #%d: %s",
                        $job->tube, $job->id, $_ ]};
                    $job->bury or die "Couldn't bury job after catching error: ", $queue->error;
                };
            }
            last if time >= $end_time;
        }
        log_debug { "Exiting after a well-lived life" };
        exit 0;
    }
}

1;
