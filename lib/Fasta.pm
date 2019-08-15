=head1 NAME

FASTA.pm -- functions to parse FASTA files for sequence data

=head1 SYNOPSIS

    use Fasta;
    
    my $seq;
    $seq = Fasta::filename2hash($filename);
    $seq = Fasta::string2hash($fasta_data);
    
    my @names = keys %$seq;
    my @seqs  = values %$seq;

=cut

use strict;
package Fasta;
use Carp qw(carp); 

my $GAP_CHAR   = ' -.';
my $LEGAL_CHAR = 'ABCDGHKMNRSTVWY';

=head1 FUNCTIONS

No functions are exported (either automatically or by request).  Call all
functions by their fully qualified name.

=head2 filename2hash

Exactly the same as L</string2hash> except the first parameter is a filename not
a string of data.

=cut

sub filename2hash {
    my $filename = shift;
    open my $fa, '<', $filename or die "Couldn't open $filename -- $!\n";
    my $data = do { local $/; <$fa> };
    close $fa or die "Error closing '$filename' -- $!\n";
    return string2hash(\$data, @_);
}

=head2 string2hash

Takes a reference to a string of FASTA data.  An optional second parameter
preserves gap characters (C<[ -.]>) if true.  Otherwise, this routine will
attempt to remove gap characters, i.e. C<[ -.]>, and warn the number of them.

Non-nucleotide characters, i.e. C<[^ABCDGHKMNRSTVWY]>, in a sequence will cause
it to be skipped and a warning will be issued.

=cut

sub string2hash {
    my %sequences;

    for my $seq (@{string2array(@_)}) {
        $sequences{$seq->{id}} = $seq->{seq};
    }

    return \%sequences;
}

sub string2array {
    my $big_string_ref = shift;
    my $keep_gaps = shift;

    my @sequences;
    my $name;
    my $desc;
    my $seq = '';

    # Use a fake last line that looks like a FASTA description to avoid
    # repeating ourselves when checking and storing the last sequence.  While
    # there are other ways to do this, this one is by far the simplest at the
    # expense of just a little cleverness.
    # -trs, 2013-10-08
    foreach (split(/[\r\n]+/, $$big_string_ref), ">eof") {
        if (my ($new_seq) = $_ =~ m/>(.+)/) {
            if ($seq ne '') { # is this one of several sequences?
                my $legal = $LEGAL_CHAR;
                if ($keep_gaps) {
                    # allow gap chars, but still sanity check for other errors
                    $legal .= $GAP_CHAR;
                } else {
                    # remove gap chars, as if they didn't exist
                    my $gap = $seq =~ s/[$GAP_CHAR]//g;
                    carp("removed $gap gap-like characters from $name") if $gap > 0;
                }
                if ($seq =~ /([^$legal])/i) {
                    carp("skipped $name because of illegal char '$1'");
                } else {
                    push @sequences, {
                        id          => $name,
                        description => $desc,
                        seq         => $seq,
                    };
                }
            }

            ($name, $desc) = split /\h/, $new_seq, 2;
            $seq = '';
        } else {
            chomp;
            $seq .= $_;
        }
    }

    return \@sequences;
}

1;

=head1 SEE ALSO

L<BioPerl>

=head1 AUTHOR

Thomas Sibley E<lt>trsibley@uw.eduE<gt>

Brandon Maust E<lt>bmaust@u.washington.eduE<gt>
