package EpitopeDB::pool_response_corravg;

use base qw/DBIx::Class/;

# Load required DBIC stuff
__PACKAGE__->load_components(qw/PK::Auto Core/);
# Set the table name
__PACKAGE__->table('epitope.pool_response_corravg');
# Set columns in table
__PACKAGE__->add_column(
    qw/
        measure_id
        bg_measure_id
        pool_id
        exp_id
        sample_id
        avg 
        corr_avg
        result
    /
);
# Set the primary key for the table
__PACKAGE__->set_primary_key(qw/measure_id/);

# relationship between pool_response_corravg and pool_response
__PACKAGE__->has_one(pool_response => 'EpitopeDB::pool_response', 'measure_id');

# one to many relationship between pool and pool_response_corravg
__PACKAGE__->belongs_to(pool => 'EpitopeDB::pool', 'pool_id');

# one to many relationship between sample and pool_response_corravg
__PACKAGE__->belongs_to(sample => 'EpitopeDB::sample', 'sample_id');


=head1 NAME

EpitopeDB::gene - A model object representing a gene.

=head1 DESCRIPTION

This is an object that represents a row in the 'gene' table of viroverse database.
It uses DBIx::Class (aka, DBIC) to do ORM. For Catalyst, this is designed to be 
used through Viroverse::Model::EpitopeDB. offline utilities may wish to use this 
class directly.

=cut

1;
