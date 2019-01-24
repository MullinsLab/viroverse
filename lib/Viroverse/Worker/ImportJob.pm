use strict;
use warnings;
use utf8;
use 5.018;

package Viroverse::Worker::ImportJob;
use Moo;

use ViroDB;
use Viroverse::Logger qw< :log :dlog >;
use Viroverse::Storage;
use JSON::MaybeXS qw< encode_json >;
use Path::Tiny;
use Try::Tiny;
use namespace::clean;

with 'Viroverse::Worker::Cron';

use constant LIFETIME           =>  5 * 60;
use constant MAX_WORKERS        =>  2;
use constant RESERVE_TIMEOUT    => 10; # Block waiting for a job for up to 10s
use constant MAIN_LOCK_INTERVAL =>  5;  # Attempt to get main lock every 5s

use constant TUBE => 'import';

sub run_job {
    my $self = shift;
    my $job = shift or die "No job";
    my $data = $job->args;

    my $db = ViroDB->instance;
    my $worker_txn = $db->txn_scope_guard;

    # Acquire a row-level lock on the job record which is only released when we
    # commit the transaction.
    my $import_job = $db->resultset("ImportJob")
        ->find($data->{import_job_id}, { for => 'update' });

    my $log_data = [];
    my $log = Viroverse::Logger->add_temp_appender(
        'Viroverse::Logger::Capture',
        array => $log_data,
    );

    try {
        my $job_txn = $db->txn_scope_guard;

        Dlog_debug { "Job config: $_" } $data;

        my $importer = $import_job->type->package->new(
            input_rows => $import_job->data_rows,
            %$data,
        );

        $importer->execute;
        $import_job->update({ time_executed => \"now()" });
        log_info { ["ImportJob %d completed", $import_job->id] };
        log_info { "Changes saved" };

        $job_txn->commit;
    } catch {
        # Log, but otherwise ignore, the error.  The inner job txn above gets
        # rolled back, but the outer worker txn will continue.  This means that
        # the import job will get its log and queue key updated, and the
        # Beanstalk job will be removed from the queue instead of buried.
        log_error { "Import job died with an error: $_" };
        log_info { "Rolling back changes" };
    };

    $log->done;

    my $logfile = Path::Tiny->tempfile;
    $logfile->spew_raw( encode_json($log_data) );

    my $storage = Viroverse::Storage->instance;
    my $log_key = $storage->put_path($logfile);

    $import_job->update({
        log_file_key  => $log_key,
        job_queue_key => undef,
    });
    $worker_txn->commit;
}

1;
