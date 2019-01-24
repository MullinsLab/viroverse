use strict;
use warnings;
use utf8;
use 5.018;

package ViroDB::ResultSet::Project;
use base 'ViroDB::ResultSet';

sub active {
    my $self = shift;
    my $me = $self->current_source_alias;
    $self->search({
        "$me.completed_date" => [ undef, { '>' => \'now()::date' } ],
    });
}

sub completed {
    my $self = shift;
    my $me = $self->current_source_alias;
    $self->search({
        "$me.completed_date" => { '<=' => \'now()::date' },
    });
}

1;
