use strict;
use warnings;
use 5.018;

package Mullins::AutopsyAbbreviations;

=head1 NAME

Mullins::AutopsyAbbreviations - provides mapping from tissue × molecule → abbreviation,
per the Autopsy Project standard designed by Jim et al.

=head1 DESCRIPTION

As specified on 2015-10-21 at https://mullinslab.microbiol.washington.edu/twiki/bin/view/BetaProtocols/SequenceNaming

=cut

# Using a map instead of something like $na_type[0] because that might not work with
# some unspecified future extension of this abbreviation scheme.
my %molecule_map = (
    DNA => 'D',
    RNA => 'R',
);

# These are the names of the tissue types in Viroverse, mapped onto the defined 2-char
# tissue abbreviations. Coding this in this way obviously violates some referential
# integrity with what's in the database but in order to sketch this all out I need to
# avoid the database for the moment.
my %vv_tissue_to_abbreviation_map = (
    # abdomen skin
    # adrenal
    # aorta
    'biological clone' => 'bc',
    'lymphocyte' => 'bL',
    'bone marrow', => 'BM', # .___.
    'monocytes' => 'bM', # >_<
    'brain' => 'Br',
    'brain (basal ganglia)' => 'Br',
    'brain (cerebellum)' => 'Br',
    'brain (frontal)' => 'Br',
    'brain (hemisphere)' => 'Br',
    'brain (hippocampus)' => 'Br',
    'brain (occipital)' => 'Br',
    'brain (parietal)' => 'Br',
    'brain (pons)' => 'Br',
    'cervix' => 'Cx',
    # BLCL
    # blood
    'blood (cells)' => 'FB',
    'blood (plasma)' => 'Pl',
    # brachial nerve
    # breast milk (L)
    # breast milk (R)
    # buccal swab
    # CBX - biopsy
    # cell, pellet
    # cervical swab
    # colon biopsy
    # colon cells
    # CSF
    # CSF cell
    # culture supernatant
    # dorsal root ganglion
    'endocervical swab' => 'ES',
    # esophagus
    # eye (choroid)
    # feces
    'GALT' => 'Ga',
    'intestine' => 'It',
    'intestine (large)' => 'LI',
    'intestine (small)' => 'SI',
    'kidney' => 'Ki',
    'kidney (left)' => 'Ki',
    'kidney (right)' => 'Ki',
    # lab strain
    # Leukapheresed cells
    'liver' => 'Lv',
    'lung' => 'Lu',
    'lung (left)' => 'Lu',
    'lung (right)' => 'Lu',
    # lymph
    'lymph node' => 'LN',
    # NSMC
    'PBMC' => 'PB',
    'PBMC(CD4-)' => 'PB',
    'PBMC(CD4+)' => 'PB',
    'PBMC(CD8-)' => 'PB',
    'PBMC(CD8+)' => 'PB',
    'plasma' => 'Pl',
    'prostate' => 'Pr',
    # rectal swab
    'rectum' => 'Re',
    # sacral nerve
    'semen' => 'Sn',
    'semen, pellet' => 'SP',
    'semen, supernatant' => 'SS',
    'serum' => 'Sr',
    # skin biopsy - tumor
    # spinal cord
    'spleen' => 'Sp',
    'T cell (non-resting)' => 'TN',
    'T cell (resting)' => 'TR',
    'T cells' => 'TC',
    'thymus' => 'Th',
    'tonsil' => 'Ts',
    # vaginal swab
    # vagus nerve
    # VOA supernatant
);

=head1 FUNCTIONS

=head2 tissue_molecule_abbreviation

Given a Viroverse tissue name and a molecule type ('DNA' or 'RNA' currently),
constructs the autopsy-style three-character abbreviation for the tissue and
molecule type.

=cut

sub tissue_molecule_abbreviation {
    my ($tissue, $molecule) = @_;
    return $vv_tissue_to_abbreviation_map{$tissue} . $molecule_map{$molecule};
}

=head2 amplicon

Given a L<Viroverse::Model::sequence::dna> object, returns the appropriate
amplicon nickname used by the Autopsy project.  While amplicons are most
directly and traditionally defined by primers, we use alignment to HXB2 for
convenience.  (Helpfully, this also avoids problems with PCR labeled with
incorrect primers.)

=cut

sub amplicon {
    my $seq  = shift;
    my $search = $seq->as_search_data;
    my ($alignment_start, undef) = $seq->hxb2_coverage;
    return undef unless $alignment_start;
    my @intersecting_regions = @{$search->regions};
    return "NFLWG" if grep { $_ eq 'NFLG' } @intersecting_regions;
    return "5pol"  if 2 == grep { $_ =~ /^(gag|pol)$/ } @intersecting_regions;
    my $env = grep { $_ eq 'env' } @intersecting_regions;
    return "C2V5"  if $env and $alignment_start > 7000;
    return "C2V3"  if $env and $alignment_start > 6800;
    return "V1V5"  if $env and $alignment_start > 6000;
    return undef;
}

1;
