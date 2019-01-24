package ViroDB::Role::HasCopyNumberSummary;

use strict;
use warnings;

use Moose::Role;

requires 'copy_numbers';

sub copy_number_summary {
    my $self = shift;
    my @copy_numbers = $self->copy_numbers;
    my %summary;
    foreach my $copy_number(@copy_numbers) {
        my $primers = join(", ", $copy_number->pcr_primers);
        push @{$summary{$primers}},
            {
                id               => $copy_number->copy_number_id,
                value            => $copy_number->value,
                date_created     => $copy_number->date_created
            };
    }
    return \%summary;
}

1;
