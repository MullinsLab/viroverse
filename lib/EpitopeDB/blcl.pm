package EpitopeDB::blcl;

use base qw/DBIx::Class/;

# Load required DBIC stuff
__PACKAGE__->load_components(qw/PK::Auto Core/);
# Set the table name
__PACKAGE__->table('epitope.blcl');
# Set columns in table
__PACKAGE__->add_column(
    qw/
        blcl_id
        name
    /
);
# Set the primary key for the table
__PACKAGE__->set_primary_key(qw/blcl_id/);

__PACKAGE__->has_many(hla_responses => 'EpitopeDB::hla_response', 'blcl_id');

=head1 NAME

EpitopeDB::blcl - A model object representing a blcl.

=head1 DESCRIPTION

This is an object that represents a row in the 'gene' table of viroverse database.
It uses DBIx::Class (aka, DBIC) to do ORM. For Catalyst, this is designed to be 
used through Viroverse::Model::EpitopeDB. offline utilities may wish to use this 
class directly.

=cut

1;
