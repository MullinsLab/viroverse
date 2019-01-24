use strict;
use warnings;
use utf8;
use 5.018;

package Viroverse::Controller::Import;

use Moose;
use Catalyst::ResponseHelpers;
use Viroverse::Logger qw< :log :dlog >;
use Viroverse::Storage;
use Beanstalk::Client;
use JSON::MaybeXS;
use List::Util qw< first >;
use String::CamelSnakeKebab qw< kebab_case >;
use Types::Standard -types;
use Viroverse::ImportType;
use File::LibMagic;
use namespace::autoclean;

BEGIN { extends 'Viroverse::Controller' }

my @import_types = Viroverse::ImportType->load_all;

sub base : Chained('/') PathPart('import') CaptureArgs(0) {
    my ($self, $c) = @_;
    return Forbidden($c)
        unless $c->stash->{scientist}->is_admin || $c->stash->{scientist}->is_supervisor;
}

sub index : Chained('base') PathPart('') Args(0) {
    my ($self, $c) = @_;
    my $previous_jobs =
      $c->model("ViroDB::ImportJob")->search({}, { order_by => { -desc => 'time_created'}});

    if (! $c->req->params->{all}) {
        $previous_jobs = $previous_jobs->search({
            -or => [
                { -not => { time_executed => undef } },
                { time_created => { '>' => \[ "now() - '1 week'::interval" ] } }
            ]
        });
    }

    $c->stash(
        template       => 'import/index.tt',
        import_types   => \@import_types,
        previous_jobs  => [ $previous_jobs->all ],
        showing_all    => $c->req->params->{all},
    );
    $c->detach('Viroverse::View::NG');
}

sub new_job : Chained('base') PathPart('new') Args(1) {
    my ($self, $c, $type) = @_;

    my $meta = first { $_->name eq $type } @import_types
        or return Forbidden($c, "Unknown importer type $type");

    $c->stash(
        template => 'import/new.tt',
        type     => $meta,
    );
    $c->detach( $c->view("NG") );
}

sub create : POST Chained('base') PathPart('') Args(0) {
    my ($self, $c) = @_;
    my $upload = $c->request->upload("data_file");
    if (!$upload) {
        my $mid = $c->set_error_msg("You must provide a data file");
        return Redirect($c, $self->action_for("index"), { mid => $mid });
    }
    my $type = $c->req->params->{type};
    my $note = $c->req->params->{note};
    if ($type = first { $_->name eq $type } @import_types) {
        my $hash = Viroverse::Storage->instance->put_path($upload->tempname);
        my $new_job = $c->model("ViroDB::ImportJob")->create({
            scientist_id   => $c->stash->{scientist}->scientist_id,
            data_file_key  => $hash,
            data_file_name => $upload->filename,
            type           => $type,
            note           => $note,
        });
        return Redirect($c, $self->action_for("prepare"), [ $new_job->id ]);
    } else {
        log_error {[ "Someone tried to use importer type %s; are they hacking?", $c->req->params->{type} ]};
        return Forbidden($c, "Unknown importer type " . $c->req->params->{type});
    }
}

sub load : Chained('base') PathPart('') CaptureArgs(1) {
    my ($self, $c, $id) = @_;
    my $import_job = $c->model("ViroDB::ImportJob")->find($id)
        or return NotFound($c,"No such import job «$id»");
    $c->stash( current_model_instance => $import_job );
}

sub show : Chained('load') PathPart('') Args(0) {
    my ($self, $c) = @_;
    state $queue = do {
        my $q = Beanstalk::Client->new;
        $q->use('import');
        $q;
    };

    $c->stash(
        template   => 'import/show.tt',
        import_job => $c->model,
        queue => $queue,
    );
    $c->detach('Viroverse::View::NG');
}

sub download_input_file : Chained('load') PathPart('download/data') Args {
    my ($self, $c) = @_;

    my $file = $c->model->data_path
        or return NotFound($c, "File for import job «" . $c->model->id . "» not found");

    state $magic = File::LibMagic->new();
    my $mime = $magic->info_from_filename($file->canonpath)->{mime_type_with_encoding};

    return FromFile($c, $file, $mime);
}

sub download_log_file : Chained('load') PathPart('download/log') Args {
    my ($self, $c) = @_;

    my $log = $c->model->log
        or return NotFound($c, "Log for import job «" . $c->model->id . "» not found");

    return FromCharString($c, $log, "text/plain; charset=UTF-8");
}

sub download_log_records : Chained('load') PathPart('download/log') Args
                           Does(MatchRequestAccepts) Accept('application/json') {
    my ($self, $c) = @_;

    my $log = $c->model->log_records
        or return NotFound($c, "Log records for import job «" . $c->model->id . "» not found");

    # XXX TODO: Use AsJSON once our View::JSON and View::JSON2 aren't stupid.
    # -trs, 29 March 2017
    return FromCharString($c,
        JSON->new->encode($log),
        'application/json; charset=UTF-8'
    );
}

sub prepare : Chained('load') PathPart('prepare') Args(0) {
    my ($self, $c) = @_;
    my $import_type    = $c->model->type;
    my $import_partial = 'import/partials/' . kebab_case($import_type->name) . '.tt';

    my @scientists = $c->model("ViroDB::Scientist")->active->order_by('name');

    $c->stash(
        import_job     => $c->model,
        help_pod       => $import_type->help_pod,
        scientists     => \@scientists,
        template       => 'import/prepare.tt',
        import_partial => $import_partial,
    );
    $c->detach('Viroverse::View::NG');
}

sub enqueue : POST Chained('load') PathPart('enqueue') Args(0) {
    my ($self, $c) = @_;
    my $params = $c->req->params;

    # Lock this import job record until after we queue a job and set the job id
    # on the record.  The job worker acquires the same lock and thus is
    # prevented from starting until we've updated the job id, preventing a race
    # between the ->put and the ->update below.
    my $txn = $c->model->result_source->schema->txn_scope_guard;
    $c->model->discard_changes({ for => 'update' });

    my $data = {
        import_job_id => $c->model->id,
        creating_scientist => delete $params->{scientist_id},
    };
    my $key_map = {};

    for my $field (keys %$params) {
        if ($field =~ /_key$/) {
            $key_map->{$field =~ s/_key$//r} = $params->{$field};
        } else {
            $data->{$field} = $params->{$field}
        }
    };

    $data->{key_map} = $key_map;

    state $queue = do {
        my $q = Beanstalk::Client->new;
        $q->use('import');
        $q;
    };

    my $job = $queue->put(
        { ttr => 300, },
        $data,
    );

    if ($job) {
        $c->model->update({
            job_queue_key => $job->id,
            log_file_key  => undef,
        });
        $txn->commit;
        return Redirect($c, $self->action_for("show"), [ $c->model->id ]);
    } else {
        return ServerError($c, $queue->error);
    }
}

1;
