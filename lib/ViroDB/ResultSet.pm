use strict;
use warnings;

package ViroDB::ResultSet;
use base 'DBIx::Class::ResultSet';

__PACKAGE__->load_components('Helper::ResultSet::Shortcut');

1;
