use utf8;
package ViroDB::Result::ImportJob;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ViroDB::Result::ImportJob

=cut

use strict;
use warnings;

=head1 BASE CLASS: L<ViroDB::Result>

=cut

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'ViroDB::Result';

=head1 TABLE: C<viroserve.import_job>

=cut

__PACKAGE__->table("viroserve.import_job");

=head1 ACCESSORS

=head2 import_job_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'viroserve.import_job_import_job_id_seq'

=head2 scientist_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 time_created

  data_type: 'timestamp with time zone'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=head2 time_executed

  data_type: 'timestamp with time zone'
  is_nullable: 1

=head2 data_file_name

  data_type: 'text'
  is_nullable: 1

=head2 data_file_key

  data_type: 'text'
  is_nullable: 1

=head2 log_file_key

  data_type: 'text'
  is_nullable: 1

=head2 job_queue_key

  data_type: 'integer'
  is_nullable: 1

=head2 type

  data_type: 'text'
  is_nullable: 0

=head2 note

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "import_job_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "viroserve.import_job_import_job_id_seq",
  },
  "scientist_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "time_created",
  {
    data_type     => "timestamp with time zone",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "time_executed",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "data_file_name",
  { data_type => "text", is_nullable => 1 },
  "data_file_key",
  { data_type => "text", is_nullable => 1 },
  "log_file_key",
  { data_type => "text", is_nullable => 1 },
  "job_queue_key",
  { data_type => "integer", is_nullable => 1 },
  "type",
  { data_type => "text", is_nullable => 0 },
  "note",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</import_job_id>

=back

=cut

__PACKAGE__->set_primary_key("import_job_id");

=head1 RELATIONS

=head2 scientist

Type: belongs_to

Related object: L<ViroDB::Result::Scientist>

=cut

__PACKAGE__->belongs_to(
  "scientist",
  "ViroDB::Result::Scientist",
  { scientist_id => "scientist_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2017-08-11 15:11:37
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:2w/nmDnAHp+8dJXkI+jUKA

use warnings;
use strict;
use 5.018;
use Viroverse::Storage;
use Viroverse::DataRectangle::Any;
use Beanstalk::Client;
use JSON::MaybeXS;
use List::Util 1.29 qw< pairmap >;
use Try::Tiny;
use Viroverse::Logger qw< :log >;
use Viroverse::ImportType;
use namespace::clean;

__PACKAGE__->inflate_column( type => {
    inflate => sub { Viroverse::ImportType->new( name => $_[0] ) },
    deflate => sub { $_[0]->name },
});

=head1 METHODS

=head2 type

Returns a L<Viroverse::ImportType> object for this job's importer type.

=head2 data_path

Returns a L<Path::Tiny> object pointing at the contents of L</data_file_key>.
You should not move this path around, only read from it.

=head2 data_header

Returns a list of strings giving the column headers of the data to be
imported. (That is, the fields of the first line of the file.)

=head2 data_rows

Returns an arrayref of hashrefs, where the keys are drawn from L</data_header>
and the values from the corresponding column of each line.

=cut

sub data_path {
    my $self = shift;
    return undef unless $self->data_file_key;

    my $path = Viroverse::Storage->instance->get_path($self->data_file_key)
        or die "Data integrity error: Can't find ", $self->data_file_key, " in storage";
    return $path;
}

sub data_rectangle {
    my $self = shift;
    my $path = $self->data_path or return;
    my $rectangle = Viroverse::DataRectangle::Any->new(
        file           => $path,
        file_extension => (split /[.]/, $self->data_file_name)[-1],
    );
}

sub data_header {
    my $self = shift;
    my $rect = $self->data_rectangle or return;
    return $rect->header;
}

sub data_rows {
    my $self = shift;
    my $rect = $self->data_rectangle or return;
    return $rect->rows;
}

=head2 log

Returns the text of the log file associated with this import job, or C<undef>
if there's no log file.

=head2 log_records

Returns an C<< ArrayRef[ Dict[ level => Str, message => Str ] ] >> of the log
messages associated with this import job, or C<undef> if there's no log file.

For log files old enough to be plain text instead of JSON (which isn't really
very old at all!), a best effort attempt is made to split the text into lines
and transform those lines into records.

=head2 has_log

Returns a boolean indicating if this import job has an associated log file.

=cut

sub has_log {
    my $self = shift;
    return !!$self->log_file_key;
}

sub log {
    my $self = shift;
    my $records = $self->log_records
        or return undef;
    return join "", map { $_->{message} } @$records;
}

sub log_records {
    my $self = shift;
    return undef unless $self->log_file_key;

    my $path = Viroverse::Storage->instance->get_path($self->log_file_key)
        or die "Data integrity error: Can't find ", $self->log_file_key, " in storage";

    my $data = $path->slurp_utf8;

    return try {
        # Already been decoded as UTF-8 for the benefit of our catch stanza, so
        # this can't use decode_json().
        return JSON->new->decode($data);
    } catch {
        log_debug { "Couldn't decode log data as JSON... assuming plain text" };
        my $not_first = 0;
        return [
            # Split lines by their log level tag at the start of a line, and
            # capture the level name, producing a list of LEVEL => MESSAGE
            # pairs which are then transformed into structured data.  Discards
            # the first element of the split which is always empty because the
            # split pattern matches the beginning of the string.

            pairmap { +{ message => "$a - $b", level => $a } }
               grep { $not_first++ }
              split /(?:^(TRACE|DEBUG|INFO|WARN|ERROR|FATAL) - )/m,
                    $data
        ];
    };
}

=head2 state

Returns a string indicating the execution status of the job:

=over 4

=item new

Job has not been queued for execution

=item queued

Job is on the queue waiting for a worker to pick it up

=item running

Job has been claimed by a worker and is (presumably) executing

=item executed

Successful execution recorded by a worker script

=item delayed

Job is waiting for a timer to run out before returning to "queued" state

=item error

Job had a fatal error and is still in the queue (Beanstalk "buried" state,
for now.)

=back

=head2 queue_status

Looks for this job on the Beanstalk tube and returns the
L<Beanstalk::Client::Stats> object giving its current state if the job is in
place.

Job IDs may be reused across restarts of a Beanstalk queue. The
L</job_queue_key> must be cleared when a job completes successfully.

=cut

sub state {
    my $self = shift;
    my $queue_status = $self->queue_status;
    return "executed" if $self->time_executed and not $queue_status;
    return "new"      if not $queue_status;
    return "running"  if $queue_status->state eq 'reserved';
    return "queued"   if $queue_status->state eq 'ready';
    return "delayed"  if $queue_status->state eq 'delayed';
    return "error"    if $queue_status->state eq 'buried';
    return "unknown";
}

sub queue_status {
    my $self = shift;

    return unless $self->job_queue_key;
    state $queue = do {
        my $q = Beanstalk::Client->new;
        $q->use('import');
        $q;
    };

    return $queue->stats_job($self->job_queue_key);
}

=head2 suggested_column_for_key

Takes a string key name and returns a suggested data column from this import
job's L</data_header>.

A small wrapper around L<the import type's|/type>
L<suggested_column_for_key method|Viroverse::Import/suggested_column_for_key>.

=cut

sub suggested_column_for_key {
    my $self = shift;
    my $key  = shift;
    return $self->type->package->suggested_column_for_key($key, $self->data_header);
}

__PACKAGE__->meta->make_immutable;
1;
