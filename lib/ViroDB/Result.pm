use strict;
use warnings;
use utf8;
use 5.018;

package ViroDB::Result;
use base 'DBIx::Class::Core';

use DateTime::Format::RFC3339;

__PACKAGE__->load_components(qw(
    InflateColumn::DateTime
    +ViroDB::SerializableAsJSON
));

sub _inflate_to_datetime {
    state $formatter = DateTime::Format::RFC3339->new;
    my $self = shift;
    my $dt   = $self->next::method(@_);
    $dt->set_formatter($formatter);
    return $dt;
}

1;
