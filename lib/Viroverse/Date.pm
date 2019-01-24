use strict;
use warnings;

package Viroverse::Date;
use DateTime::Format::Strptime qw(strptime);
use namespace::autoclean;

=head2 parse_with_op

Expects a date string as the first argument, which it attempts to parse and
normalize.

Returns a tuple of (operator, YYYY-MM-DD) on success or an empty list if the
date cannot be parsed.

The date string may have a comparison operator at the begining such as C<< <
>>, C<< > >>, C<< <= >>, C<< >= >>, or C<< = >>.  If no operator is specified,
the default returned is C<=>.

=cut

sub parse_with_op {
    my ($self, $date) = @_;

    $date =~ s/(^\s+|\s+$)//g;
    my $op   = $date =~ s/^([<>]=?|=)\s*// ? $1 : "=";
    my $iso;

    for my $pattern ('%Y-%m-%d', '%m/%d/%Y', '%m/%d/%y') {
        if (my $dt = eval { strptime($pattern, $date) }) {
            $iso = $dt->ymd;
            last;
        }
    }
    return $iso ? ($op, $iso) : ();
}

1;
