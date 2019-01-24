use strict;
use warnings;
use utf8;
use 5.018;

package Viroverse::Import::Primers;
use Moo;
use Types::Standard -types;
use ViroDB;
use Viroverse::Logger qw< :log :dlog >;
use Viroverse::Types qw< :types >;
use namespace::clean;

with 'Viroverse::Import';

has organism => (
    is       => 'ro',
    isa      => ViroDBRecord["Organism"],
    coerce   => 1,
    required => 1,
);

has _primer_rs => (
    is      => 'ro',
    isa     => InstanceOf["DBIx::Class::ResultSet"],
    default => sub { ViroDB->instance->resultset("Primer") },
);

has '+key_map' => (
    is  => 'ro',
    isa => Dict[
        name        => Str,
        sequence    => Str,
        orientation => Str,
        lab_common  => Optional[Str],
        notes       => Optional[Str],
        hxb2_start  => Optional[Str],
        hxb2_end    => Optional[Str],
    ],
);

sub suggested_column_for_key_pattern {
    my ($package, $key) = @_;
    return {
        orientation => qr/orientation|direction/i,
        lab_common  => qr/common/i,
        hxb2_start  => qr/hxb.*start/i,
        hxb2_end    => qr/hxb.*(end|finish)/i,
    }->{$key};
}

=head1 DESCRIPTION

=encoding UTF-8

This importer loads primers.

For each row of input, existing primers are searched for first by name and
sequence, then just name, and finally just sequence.  Matching is
case-insensitive.

Any match to an existing primer will cause the input row to be skipped, except
to add any new HXB2 positions.  Warnings will be output to the log if the
existing primer was matched only by name or sequence, and these should likely be
resolved manually by adjusting the input file.

If no existing primers are found, a new primer is created for the input row.

Rows without a name and sequence (i.e. empty rows) are skipped.

All primers in an import batch must be for the same organism.

If a primer has multiple HXB2 positions, these can be provided via multiple
rows where all of the other values are equal.

HXB2 positions can only be added to HIV-1 and HIV-2 primers.

=cut

sub process_row {
    my ($self, $row) = @_;

    unless ($row->{name} and $row->{sequence}) {
        log_debug { "Skipping empty row" };
        $self->track("Skipped empty row");
        return;
    }

    my ($existing, $mismatched) = $self->find_existing($row);
    if ($existing) {
        $self->track("Found existing");

        # The primer already exists, but this might be an additional position
        # for a previous primer in this import
        if ($row->{hxb2_start} and $row->{hxb2_end}) {
            if ($mismatched) {
                log_warn {"Not adding position to mismatched primer"};
                $self->track("Skipping position for mismatched primer");
            } else {
                $self->add_position($existing, $row);
            }
        }
    } else {
        log_debug { "Creating primer $row->{name}" };

        my $primer = $self->_primer_rs->create({
            name        => $row->{name},
            sequence    => $row->{sequence},
            orientation => normalize_orientation($row->{orientation}),
            organism    => $self->organism,

            # I don't think we don't need to normalize this because Pg already
            # does a pretty good job of casting text to booleans.
            lab_common => $row->{lab_common},
            notes      => $row->{notes},
        });

        log_info {[ "Created primer %s (#%d)", $primer->name, $primer->id ]};
        $self->track("Created primer");

        if ($row->{hxb2_start} and $row->{hxb2_end}) {
            $self->add_position($primer, $row);
        }
    }
}

sub find_existing {
    my ($self, $row) = @_;

    my $primers_for_organism = $self->_primer_rs->search({
        organism_id => $self->organism->id
    });

    my ($n, $s) = @$row{qw[ name sequence ]};
    my @queries = (
        { name => $n, sequence => $s },
        { name => $n },
        { sequence => $s },
    );

    for my $query (@queries) {
        # Convert queries to case-insensitive matches of the form:
        #   \['lower(name) = lower(?) AND lower(sequence) = lower(?)', $name, $seq]
        #
        my $query_lower = \[
            join(" AND ", map { "lower($_) = lower(?)" } keys %$query),
            values %$query,
        ];

        if (my @primers = $primers_for_organism->search($query_lower)) {
            my $query_keys = join " + ", sort keys %$query;

            log_info {[
                "Found %s using %s for %s - %s",
                join(", ", map { $_->name } @primers),
                $query_keys,
                $row->{name},
                $row->{sequence}
            ]};
            $self->track("Found by $query_keys");

            my $mismatched = 0;

            if ($primers[0]->name ne $row->{name}) {
                log_warn {"Name mismatch!"};
                $self->track("Mismatch - name");
                $mismatched = 1;
            }

            if ($primers[0]->sequence_bases ne $row->{sequence}) {
                log_warn {"Sequence mismatch!"};
                $self->track("Mismatch - sequence");
                $mismatched = 1;
            }

            return ($primers[0], $mismatched);
        }
    }

    return 0;
}

sub normalize_orientation {
    my $dir = shift;
    return "F" if $dir =~ /^( f(orward)? | \+ )$/ix;
    return "R" if $dir =~ /^( r(everse)? |  - )$/ix;

    Dlog_warn { "Unable to normalize orientation: $_" } $dir;
    return undef;
}

sub add_position {
    my ($self, $primer, $row) = @_;

    unless ($row->{hxb2_start} and $row->{hxb2_end}) {
        log_debug {"No position provided"};
        return
    }

    unless ($self->organism->name =~ /HIV-[12]/i) {
        log_warn {"Attempted to add primer position to non-HIV organism ($self->organism->name)"}
        $self->track("Can't add primer to non-HIV organism");
        return
    }

    my $pos = $primer->positions->find_or_new({
        hxb2_start => $row->{hxb2_start},
        hxb2_end   => $row->{hxb2_end},
    });
    if (!$pos->in_storage) {
        log_debug {[
            "Primer %s: added position %s--%s",
            $primer->name, $pos->hxb2_start, $pos->hxb2_end
        ]};
        $self->track("Added position");
        $pos->insert;
    }
}

1;
