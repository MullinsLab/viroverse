package EpitopeDB::measurement;

use base qw/DBIx::Class/;

# Load required DBIC stuff
__PACKAGE__->load_components(qw/PK::Auto Core/);
# Set the table name
__PACKAGE__->table('epitope.measurement');
# Set columns in table
__PACKAGE__->add_column(
    qw/    measure_id /
);
# Set the primary key for the table
__PACKAGE__->set_primary_key(qw/measure_id/);

__PACKAGE__->might_have(pept_response => 'EpitopeDB::pept_response', 'measure_id');

__PACKAGE__->has_many(readings => 'EpitopeDB::reading', 'measure_id');

=head1 NAME

EpitopeDB::gene - A model object representing a gene.

=head1 DESCRIPTION

This is an object that represents a row in the 'gene' table of viroverse database.
It uses DBIx::Class (aka, DBIC) to do ORM. For Catalyst, this is designed to be 
used through Viroverse::Model::EpitopeDB. offline utilities may wish to use this 
class directly.

=cut

1;
