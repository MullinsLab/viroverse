use strict;
use warnings;
use 5.018;

package Mullins::MedicationAbbreviations;
use base 'Exporter';

our @EXPORT_OK = qw( canonicalize_medication_abbreviation );

my %renamed_meds = qw(
    TNV TDF
    ETV ETR
    RLP RPV
    ATZ ATV
    FOS FPV
    MRV MVC
    ELV EVG
    RLT RAL
    TA  TAF
    COB COBI
);

sub canonicalize_medication_abbreviation {
    my $abbr = shift;
    return $renamed_meds{$abbr} || $abbr;
}

1;
