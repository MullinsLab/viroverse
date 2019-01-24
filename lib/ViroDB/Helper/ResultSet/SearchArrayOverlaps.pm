use strict;
use warnings;
package ViroDB::Helper::ResultSet::SearchArrayOverlaps;
use Moose::Role;

requires 'current_source_alias';
requires 'result_source';
requires 'search';

sub search_array_overlaps {
    my $self   = shift;
    my $column = shift;
    my $me     = $self->current_source_alias;
    my $type   = $self->result_source->column_info($column)->{data_type} || "text[]";
    my @conditions;

    # Does the array overlap with the given strings?
    if (my @names = grep { defined } @_) {
        push @conditions, {
            '&&' => \[
                "ARRAY[" . join(',', ('?') x @names) . "]::$type",
                @names
            ]
        };
    }

    # Does the array contain a single element, NULL?  The array overlap
    # operator (&&) will return false for ARRAY[NULL] && ARRAY[NULL] because
    # element-wise comparison would lead to comparisons of null which produce
    # null.  In our model, undefined values represent null, or unknown, and are
    # a legitimate value to search by.  The underlying view shouldn't ever
    # produce an array that contains both NULL and other values, so we can rely
    # on the array equality operator.
    if (grep { not defined } @_) {
        push @conditions, {
            '=' => \["ARRAY[NULL]::$type"]
        };
    }

    return $self->search({ "$me.$column" => \@conditions });
}

1;
