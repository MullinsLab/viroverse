use strict;
use warnings;
use utf8;
use 5.018;

package ViroDB::ResultSet::Extraction;
use base 'ViroDB::ResultSet';

sub dna {
    my $self = shift;
    $self->search(
      { 'extract_type.name' => 'DNA' },
      { join => 'extract_type' }
    );
}

sub rna {
    my $self = shift;
    $self->search(
      { 'extract_type.name' => 'RNA' },
      { join => 'extract_type' }
    );
}

1;
