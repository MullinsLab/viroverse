use strict;
use warnings;

package ViroDB::ResultSet::Medication;
use base 'ViroDB::ResultSet';

sub new_unknown {
    my $self = shift;
    return $self->new_result({
        name          => 'Unknown ART',
        abbreviation  => 'Unk. ART',
        arv_class     => {
            name         => 'Unknown',
            abbreviation => 'Unknown',
        },
    });
}

1;
