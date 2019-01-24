package EpitopeDB::experiment;

use base qw/DBIx::Class/;

# Load required DBIC stuff
__PACKAGE__->load_components(qw/PK::Auto Core/);
# Set the table name
__PACKAGE__->table('epitope.experiment');
# Set columns in table
__PACKAGE__->add_column(
    qw/    exp_id
        exp_date
        plate_no 
        note
    /
);
# Set the primary key for the table
__PACKAGE__->set_primary_key(qw/exp_id/);

# one to manay relationship between experiment and pept_response
__PACKAGE__->has_many(pept_responses => 'EpitopeDB::pept_response', 'exp_id');

# one to manay relationship between experiment and titration
__PACKAGE__->has_many(titrations => 'EpitopeDB::titration', 'exp_id');

# one to manay relationship between experiment and hla_response
__PACKAGE__->has_many(hla_responses => 'EpitopeDB::hla_response', 'exp_id');

# one to manay relationship between experiment and pool_response
__PACKAGE__->has_many(pool_response => 'EpitopeDB::pool_response', 'exp_id');

=head1 NAME

EpitopeDB::gene - A model object representing a gene.

=head1 DESCRIPTION

This is an object that represents a row in the 'gene' table of viroverse database.
It uses DBIx::Class (aka, DBIC) to do ORM. For Catalyst, this is designed to be 
used through Viroverse::Model::EpitopeDB. offline utilities may wish to use this 
class directly.

=cut

1;
