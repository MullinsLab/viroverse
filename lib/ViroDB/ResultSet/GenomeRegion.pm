use strict;
use warnings;
use utf8;

package ViroDB::ResultSet::GenomeRegion;
use base 'ViroDB::ResultSet';

sub cds_regions {
    my $self = shift;
    my $me   = $self->current_source_alias;
    return $self->search({
        "$me.name" => [qw[ 5LTR gag pol vif vpr tat1 tat2 rev1 rev2 vpu env nef 3LTR ]]
    });
}

1;
