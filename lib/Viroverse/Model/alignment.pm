package Viroverse::Model::alignment;
use base 'Viroverse::CDBI';
use 5.018;
use strict;
use warnings;
use Class::DBI::AbstractSearch;
use Viroverse::session;
use Viroverse::Model::alignment_method;
use Viroverse::Model::na_sequence_alignment;
use Viroverse::Model::na_sequence_alignment_pairwise;
use Viroverse::Model::sequence::dna;
use Data::Dump;
use Fasta;
use Carp qw[croak];
use List::Compare;
use List::AllUtils qw< each_arrayref >;
use Try::Tiny;

__PACKAGE__->table('viroserve.alignment');
__PACKAGE__->sequence('viroserve.alignment_alignment_id_seq');
__PACKAGE__->columns(Primary => qw[ alignment_id alignment_revision alignment_taxa_revision ]);
__PACKAGE__->columns(Other => qw[
    alignment_length
    name
    date_entered
    alignment_method_id
    scientist_id
    note
    vv_uid
    ]
);
__PACKAGE__->has_a(scientist_id => 'Viroverse::Model::scientist');
__PACKAGE__->has_a(alignment_method_id => 'Viroverse::Model::alignment_method');

# __PACKAGE__->has_many(na_sequences => ['Viroverse::Model::na_sequence_alignment' => 'na_sequence_id'],{order_by => 'na_sequence_id'});
sub na_sequences {
    my $self = shift;
    my @aligned = Viroverse::Model::na_sequence_alignment->search_where(
        { $self->pk_pairs },
        { order_by => "na_sequence_id, na_sequence_revision DESC" },
    );
    return map $_->na_sequence_id, @aligned;
}

sub add_to_na_sequences {
    my ($self, $data) = @_;
    return Viroverse::Model::na_sequence_alignment->insert({
        $self->pk_pairs,
        %$data,
    });
}

sub pairwise_pieces {
    my $self = shift;
    my @pieces = Viroverse::Model::na_sequence_alignment_pairwise->search_where(
        { $self->pk_pairs },
        { order_by => [qw( sequence_start reference_start )] }
    );
    return @pieces;
}

sub pk_pairs {
    map {; $_ => $_[0]->$_ } $_[0]->primary_columns
}

#alias for enum to work
sub date_completed {
    my $self = shift;
    return $self->date_entered;
}

# XXX TODO: For now, only return 1/3 of the PK because too much code expects it.
# -trs, 15 Nov 2013
sub give_id { $_[0]->alignment_id }
sub get_id  { $_[0]->alignment_id }

sub idrev {
    my $self = shift;
    return join ".", $self->id;
}

sub retrieve {
    my ($pkg, $alignment_id, $revision, $taxa_rev) = @_;
    my $search;

    # Support loading by id.rev[.taxa_rev]
    ($alignment_id, $revision, $taxa_rev) = split /\./, $alignment_id
        if $alignment_id =~ /^\d+\.\d+(?:\.\d+)?$/;

    if ($revision and $taxa_rev) {
        return $pkg->SUPER::retrieve(
            alignment_id            => $alignment_id,
            alignment_revision      => $revision,
            alignment_taxa_revision => $taxa_rev,
        );
    }
    elsif ($revision) {
        $search = $pkg->search(
            alignment_id        => $alignment_id,
            alignment_revision  => $revision,
            { order_by => 'alignment_taxa_revision DESC' }
        );
    }
    else {
        $search = $pkg->search(
            alignment_id => $alignment_id,
            { order_by => 'alignment_revision DESC, alignment_taxa_revision DESC' }
        );
    }
    return $search->first;
}

sub insert {
    my $self = shift;
    my $data = shift;

    unless (defined $data->{alignment_id}) {
        # CDBI method relying on ->sequence set above
        $data->{alignment_id} = $self->_next_in_sequence;
    }
    return $self->SUPER::insert($data, @_);
}

sub to_string {
    my $self = shift;
    return ($self->name||'')." ".$self->alignment_id.'.'.$self->alignment_revision;

}

sub is_needle {
    my $method = $_[0]->alignment_method_id
        or return;
    return $method->name eq 'needle';
}

=head2 needle_align

Aligns two passed L<Viroverse::Model::sequence::dna> objects using EMBOSS
needle.  IDs may be passed instead of objects.  The first sequence is expected
to be the "reference" and the second the "query".

needle produces a global pairwise nucleotide alignment, and we figure out how
to represent it relative to the reference (the first sequence).  Insertions
with respect to the reference are considered expansions of the left-most
nucleotide.

=cut

sub needle_align {
    my $self = shift;
    my @seq  = (shift, shift);
    my $opts = shift;

    croak "need two sequence objects or IDs"
        unless grep(defined, @seq) == 2;

    for my $seq (@seq) {
        $seq = Viroverse::Model::sequence::dna->retrieve($seq)
            unless ref $seq;
    }

    my $aligned               = $self->_run_needle(@seq, $opts->{needle});
    my ($ref_pos, $query_pos) = $self->_parse_alignment_pairwise(@$aligned);

    if ($opts->{store}) {
        my $db_align = try {
            Viroverse::CDBI->db_Main->begin_work;

            my $db_align = Viroverse::Model::alignment->insert({
                alignment_length        => length $aligned->[0],
                alignment_method_id     => Viroverse::Model::alignment_method->search_single("needle"),
                alignment_revision      => 1,
                alignment_taxa_revision => 1,
                scientist_id            => 0,
            });

            $db_align->add_to_na_sequences({ $seq[0]->pk_pairs, is_reference => 1 });
            $db_align->add_to_na_sequences({ $seq[1]->pk_pairs, is_reference => 0 });

            my $iterator = each_arrayref($ref_pos, $query_pos);
            while (my ($r, $q) = $iterator->()) {
                Viroverse::Model::na_sequence_alignment_pairwise->insert({
                    $db_align->pk_pairs,
                    reference_start => $r->[0],
                    reference_end   => $r->[1],
                    sequence_start  => $q->[0],
                    sequence_end    => $q->[1],
                });
            }
            Viroverse::CDBI->db_Main->commit;
            $db_align;
        } catch {
            Viroverse::CDBI->db_Main->rollback;
            die "Storing needle alignment failed: $_";
        };
        return $db_align;
    } else {
        return ($ref_pos, $query_pos);
    }
}

sub _run_needle {
    my $self = shift;
    my @seq  = (shift, shift);
    my $opts = shift || {};

    my @seq_fasta;
    for my $seq (@seq) {
        push @seq_fasta, File::Temp->new( TMPDIR => 1 );
        print { $seq_fasta[-1] } $seq->get_FASTA, "\n";
    }

    my %needle_opts = (
        %$opts,
        asequence    => $seq_fasta[0],
        bsequence    => $seq_fasta[1],
        snucleotide1 => '',
        sformat1     => 'fasta',
        snucleotide2 => '',
        sformat2     => 'fasta',
        stdout       => '',
        aformat3     => 'fasta',
        auto         => '',
    );
    my @needle_opts = map {; "-$_", $needle_opts{$_} || () } sort keys %needle_opts;

    open my $pipe, "-|", $Viroverse::config::needle, @needle_opts
        or die "failed to run $Viroverse::config::needle: $!";

    my $aligned = $self->_read_fasta_to_array($pipe);

    close $pipe or die "closing pipe from needle failed: $!";

    # sanity checks
    @$aligned == 2
        or die "expected two aligned sequences from needle, got ", scalar @$aligned;
    length $aligned->[0] == length $aligned->[1]
        or die "aligned sequences have different lengths!";

    return $aligned;
}

sub _read_fasta_to_array {
    my ($self, $fh) = @_;
    my $count = -1;
    my @aligned;
    while (<$fh>) {
        chomp;
        s/\s+//g;
        if (/^>/) {
            $count++;
            next;
        } else {
            $aligned[$count] .= $_;
        }
    }
    return \@aligned;
}

sub _parse_alignment_pairwise {
    my ($self, $ref, $query) = @_;

    # Remove leading and trailing runs of gaps, which is very common since many
    # query fragments are contained within the reference.  We keep track of how
    # much we removed off the front to readjust ref positions later, but don't
    # care about the end.
    my $offset = 0;
    substr($ref, $-[0], $offset = $+[0]) = '' if $query =~ s/^-+//;
    substr($ref, $-[0], $+[0]          ) = '' if $query =~ s/-+$//;

    # Sanity checks
    length $ref == length $query
        or die "unequal alignment lengths!";

    for (0 .. length($ref) - 1) {
        die "gap in both reference and query at position $_!  is this a pairwise alignment?"
            if substr($ref, $_, 1) eq "-" and substr($query, $_, 1) eq "-";
    }

    # rcoords and qcoords are our pairwise regions representing the alignment.
    # We deal in 1-based, fully-closed positions.
    #
    # The idea here is to:
    #   1. Split the aligned reference into runs (segments) of gapped or
    #      non-gapped positions
    #   2. Chunk up the aligned query into substrings corresponding to the
    #      reference runs
    #   3. Split those query chunks into runs of gapped or non-gapped positions
    #   4. Expand each reference run to match the new query runs, if necessary
    #
    # The final result is the reference and query split up into runs of gapped
    # or non-gapped positions across both sequences.
    my @rsegments = _parse_alignment_segments($ref);
    my @rcoords   = _parse_segment_coords($ref, @rsegments);

    my $pos  = 0;
    my $qpos = 0;
    my @qcoords;

    # This acts as a map/filter over @rcoords by removing all elements and
    # pushing back new element(s).
    for my $rcoord (splice @rcoords) {
        my $rsegment = shift @rsegments;

        # Find the query subseq for this reference segment, and split the
        # subseq into segments (the query may contain deletions).
        my $subseq   = substr $query, $pos, length $rsegment;
        my @segments = _parse_alignment_segments($subseq);

        # Map the subseq-relative coordinates of each segment into absolute
        # positions on the query.
        push @qcoords, map {
            [ map { $_ + $qpos } @$_ ]
        } _parse_segment_coords($subseq, @segments);

        $pos  += length $rsegment;
        $qpos += length $subseq =~ s/-//gr;

        # If we have multiple segments for this part of the query, we need to
        # expand the single reference segment to match the multiple query
        # segments.  (This means there's at least one deletion in the query.)
        my $rpos = $rcoord->[0] - 1;
        if (@segments > 1) {
            push @rcoords, map { [ $rpos + 1, $rpos += length ] } @segments;
            $rpos == $rcoord->[1]
                or die "failed to expand reference segments: $rpos != $rcoord->[1]";
        } else {
            push @rcoords, $rcoord;
        }
    }

    die "failed to parse alignment: mismatching number of pairwise segments"
        unless @rcoords == @qcoords;

    # Adjust reference positions if we trimmed gaps at the start
    @rcoords = map { [ map { $_ + $offset } @$_ ] } @rcoords;

    return (\@rcoords, \@qcoords);
}

sub _parse_alignment_segments {
    # split sequence into runs of gaps and bases
    # (capturing parens preserve delim)
    my @s = split /(-+)/, shift;

    # remove leading empty string if sequence started with a gap
    shift @s if not length $s[0];
    return @s;
}

sub _parse_segment_coords {
    my $seq   = shift;
    my @parts = @_ ? @_ : _parse_alignment_segments($seq);

    # Indels are marked by the left-most position before the gap, i.e. indels
    # occur to the right of the given position.  Positions are relative to the
    # sequence without gaps (hence we only increment $pos for non-gaps).
    my $pos = 0;
    @parts = map {
        if (/-/) {
            [ $pos, $pos ];
        } else {
            [ $pos + 1, $pos += length ];
        }
    } @parts;

    my $len = length($seq =~ s/-//gr);
    $pos == $len
        or die "failed to construct segment coords: $pos != $len";

    return @parts;
}

# XXX TODO: This is basically an expanded CIGAR string... and maybe operation
# should just be a column on pairwise?  (Although it would need to query for
# sibling records.)
# -trs, 21 July 2015
sub pairwise_ops {
    my $self = shift;
    return unless $self->is_needle;

    my (@ops, $prev);
    for my $p ($self->pairwise_pieces) {
        my $op = ($prev and $prev->sequence_end  == $p->sequence_start)  ?  "deletion" :
                 ($prev and $prev->reference_end == $p->reference_start) ? "insertion" :
                                                                              "contig" ;
        push @ops, {
            operation => $op,
            map { $_ => $p->$_ }
                qw[sequence_start sequence_end
                   reference_start reference_end],
        };
        $prev = $p;
    }
    return @ops;
}

sub _build_needle_fasta {
    my $self = shift;
    return unless $self->is_needle;
    return _build_needle_fasta_from_pieces( $self->na_sequences, $self->pairwise_pieces );
}

sub _build_needle_fasta_from_pieces {
    my ($ref, $query, @pieces) = @_;
    my $unaligned = [ map { $_->seq =~ s/[^A-Za-z]//gr } $ref, $query ];
    my $pairwise  = [ [], [] ];

    for (@pieces) {
        push @{$pairwise->[0]}, [ $_->reference_start, $_->reference_end ];
        push @{$pairwise->[1]}, [ $_->sequence_start,  $_->sequence_end  ];
    }

    # Add a synthetic indel to the front if necessary
    if ($pairwise->[0][0][0] > 1 or $pairwise->[1][0][0] > 1) {
        for my $pairs (@$pairwise) {
            unshift @$pairs, $pairs->[0][0] > 1
                ? [1, $pairs->[0][0] - 1]
                : [0, 0];
        }
    }

    # Add a synthetic indel to the end if necessary
    if (   $pairwise->[0][-1][1] < length $unaligned->[0]
        or $pairwise->[1][-1][1] < length $unaligned->[1]) {

        for my $seq (0..1) {
            my $pairs = $pairwise->[$seq];
            my $len   = length $unaligned->[$seq];
            push @$pairs, $pairs->[-1][1] < $len
                ? [$pairs->[-1][1] + 1, $len]
                : [$len, $len];
        }
    }

    # Collect pieces
    my $aligned;
    for my $seq (0..1) {
        for my $piece (0 .. $#{ $pairwise->[$seq] }) {
            # Indels are represented by a pairwise record where the start
            # equals the previous end:
            #
            #    sequence_start == previous_sequence_end  → deletion relative to reference
            #   reference_start == previous_reference_end → insertion relative to reference
            #
            my ($start, $end) = @{ $pairwise->[$seq][$piece] };
            my $prev_end      = $pairwise->[$seq][$piece - 1][1];
            $aligned->[$seq] .=
                ($start == $prev_end or ($start == 0 and $end == 0))
                    ? "-" x ( $pairwise->[!$seq][$piece][1] - $pairwise->[!$seq][$piece][0] + 1 )
                    : substr( $unaligned->[$seq], $start - 1, $end - $start + 1 );
        }
    }
    return join "\n",
        ">" . $ref->fasta_description,   $aligned->[0],
        ">" . $query->fasta_description, $aligned->[1],
        "";
}

sub fasta {
    my $self = shift;
    return $self->_build_needle_fasta if $self->is_needle;
    return;
}

my $qual_essential_columns = __PACKAGE__->qualified_columns();

# Part of this query also appears in the hxb2_stats view
__PACKAGE__->set_sql('hxb2_by_seq' => qq[
    SELECT distinct $qual_essential_columns
      FROM __TABLE__
      JOIN viroserve.na_sequence_alignment s ON (
            alignment.alignment_id              = s.alignment_id
        AND alignment.alignment_revision        = s.alignment_revision
        AND alignment.alignment_taxa_revision   = s.alignment_taxa_revision
      )
      JOIN viroserve.na_sequence_alignment r ON (
            s.alignment_id              = r.alignment_id
        AND s.alignment_revision        = r.alignment_revision
        AND s.alignment_taxa_revision   = r.alignment_taxa_revision
        AND r.is_reference IS TRUE
        AND r.na_sequence_id  = 0
        AND s.na_sequence_id != 0
      )
      JOIN viroserve.na_sequence_alignment_pairwise pairwise ON (
            alignment.alignment_id              = pairwise.alignment_id
        AND alignment.alignment_revision        = pairwise.alignment_revision
        AND alignment.alignment_taxa_revision   = pairwise.alignment_taxa_revision
      )
     WHERE s.na_sequence_id = ?
       AND s.na_sequence_revision = ?
        ORDER by alignment_id DESC
]);

__PACKAGE__->set_sql('by_seq' => qq[
    SELECT distinct $qual_essential_columns
      FROM __TABLE__
      JOIN __TABLE(Viroverse::Model::na_sequence_alignment)__ USING (alignment_id, alignment_revision, alignment_taxa_revision)
     WHERE na_sequence_id = ?
       AND na_sequence_revision = ?
]);

sub taxa_count {
    my $self = shift;

    return scalar $self->na_sequences;

}

sub TO_JSON {
    my $self = shift;

    return {
        id => $self->give_id.'.'.$self->alignment_revision,
        rev => $self->alignment_revision,
        name => $self->to_string,
        completed => $self->date_completed,
        scientist_name=> $self->scientist_id->name,
    }
}

sub transform_search {
    my ($pkg, %args) = @_;

    if ($args{date_completed}) {
        $args{date_entered} = $args{date_completed};
        delete $args{date_completed};
    }

    warn Data::Dump::dump(\%args);

    return %args;
}

1;
