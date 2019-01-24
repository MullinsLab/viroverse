use strict;
use warnings;
use utf8;
use 5.018;

package Viroverse::Import;
use Moo::Role;
use ViroDB;
use Viroverse::Logger qw< :log :dlog >;
use Types::Standard -types;
use List::Util 1.29 qw< pairmap pairgrep max first >;
use Scalar::Util qw< blessed >;

=head1 NAME

Viroverse::Import

=head1 DESCRIPTION

The Import role defines the interface for I<importers>, modules which, given
tabular input data and some global parameters, execute a procedure once per row
of input data.

=head1 REQUIRES

=head2 process_row

Consumers must implement the L</process_row> method. It is called once for each
row of input. Each call to L</process_row> receives as an argument a hashref
where the keys are the keys of L</key_map> and the values are string data from
the input.

=cut

requires 'process_row';

=head1 ATTRIBUTES

=head2 key_map

isa: C<Hashref[Str]>.

L</key_map> maps keys used by L</process_row> to keys (i.e. column headers)
used in the L</input_rows>. Consumers of L<Viroverse::Import> should override
L<key_map> and set a L<Dict|Types::Standard/Structured> constraint specifying
the keys their L</process_row> implementation requires.

=cut

has key_map => (
    is => 'ro',
    isa => HashRef[Str],
);

=head2 input_rows

An array of hashrefs of user input. Keys are column or attribute names from the
input format and are unconstrained. L</process_row> implementations should not
look directly into the L</input_rows>; blindness and impedance mismatch may
result.

=cut

has input_rows => (
    is => 'ro',
    isa => ArrayRef[HashRef],
);

has _tracker => (
    is       => 'rw',
    default  => sub { {} },
    init_arg => 0,
);


=head1 METHODS

=head2 execute

Calls L</process_row> once per input row, with values mapped to the keys of
L</key_map>.

=cut

sub execute {
    my $self = shift;
    for my $input_row (@{ $self->input_rows }) {
        my $renamed_row = $self->map_input_keys($input_row);
        $self->process_row($renamed_row);
    }
    $self->_log_summary($self->_tracker);
}

=head2 map_input_keys

Takes an input row as a HashRef and uses L</key_map> to extract mapped values.
Returns a HashRef with the keys of L</key_map> and values from the input row.
Optional keys will not be present in the return value unless they have a
defined and non-empty string value in L</key_map>.

=cut

sub map_input_keys {
    my ($self, $input_row) = @_;
    Dlog_debug {"Input row: $_"} $input_row;
    return {
         pairmap { $a => $input_row->{$b} }
        pairgrep { defined $b and length $b }
                %{ $self->key_map }
    };
}

=head2 track

Given an "event name" as an argument, increments a counter for that event.
Intended to be called from L</process_row> implementations to generate a
simple summary count of actions taken. The counter values are printed to
the log by L</execute>.

=cut

sub track {
    my ($self, $event) = @_;
    $self->_tracker->{$event}++;
}

sub _log_summary {
    my ($self, $count_table) = @_;
    return unless keys %$count_table;

    log_info { ".•°•. Import Summary .•°•." };

    my $label_width = max map { length $_ } keys %$count_table;
    my $count_width = max map { length $_ } values %$count_table;

    for my $event (sort keys %$count_table) {
        log_info {[ "%-*s = %*d", $label_width, $event, $count_width, $count_table->{$event} ]};
    }
}

=head1 STATIC METHODS

=head2 metadata

Returns the L<Viroverse::ImportType> instance for the calling class.  Note that
L<Viroverse::ImportType> instances are singletons for any given class, similar
to Moose's metaclasses, which is useful for modifying their defaults.

=cut

sub metadata {
    my $package = shift;
    return Viroverse::ImportType->new( package => blessed($package) || $package );
}

=head2 suggested_column_for_key

Takes two arguments, a Str and an ArrayRef[Str].  The first should be an
standard import field key.  The arrayref should contain the column names of the
input file, possibly pre-filtered.  Returns the first value from the arrayref
which might be appropriate for the given key in L</key_map>.

The default implementation of this is simply a case-insensitive substring match
of the key against column names.  Consumers of this role are expected to
provide their own L</suggested_column_for_key_pattern> method to override this
behaviour on a per-key basis.

=head2 suggested_column_for_key_pattern

Takes a single string argument representing the name of standard import field
key.  Returns a RegexpRef for use in L</suggested_column_for_key>.  Returning
C<undef> will cause L</suggested_column_for_key> to fall back to its default
pattern described above.

=cut

sub suggested_column_for_key {
    my ($package, $key, $columns) = @_;
    my $pattern = $package->suggested_column_for_key_pattern($key)
               // qr/\Q$key\E/i;
    return first { /$pattern/ } @$columns;
}

sub suggested_column_for_key_pattern { }

=head2 is_enabled

Returns 1/truthy if the importer is enabled, and 0/falsy if it is disabled.

If this method is missing, we assume the importer is enabled.

=cut

sub is_enabled {
    return 1;
}


1;
