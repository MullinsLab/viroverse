package EpitopeDB::reading;

use base qw/DBIx::Class/;

# Load required DBIC stuff
__PACKAGE__->load_components(qw/PK::Auto Core/);
# Set the table name
__PACKAGE__->table('epitope.reading');
# Set columns in table
__PACKAGE__->add_column(
    qw/
        measure_id 
        value
        reading_id
        /
);
# Set the primary key for the table
__PACKAGE__->set_primary_key(qw/reading_id/);

__PACKAGE__->belongs_to(pept_response => 'EpitopeDB::pept_response', 'measure_id');
__PACKAGE__->belongs_to(titration => 'EpitopeDB::titration', 'measure_id');
__PACKAGE__->belongs_to(hla_response => 'EpitopeDB::hla_response', 'measure_id');
__PACKAGE__->belongs_to(pool_response => 'EpitopeDB::pool_response', 'measure_id');


=head1 NAME

EpitopeDB::hla - A model object representing a hla type.

=head1 DESCRIPTION

This is an object that represents a row in the 'gene' table of viroverse database.
It uses DBIx::Class (aka, DBIC) to do ORM. For Catalyst, this is designed to be 
used through Viroverse::Model::EpitopeDB. offline utilities may wish to use this 
class directly.

=cut

1;
