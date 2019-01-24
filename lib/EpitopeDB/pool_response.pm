package EpitopeDB::pool_response;

use base qw/DBIx::Class/;

# Load required DBIC stuff
__PACKAGE__->load_components(qw/PK::Auto Core/);
# Set the table name
__PACKAGE__->table('epitope.pool_response');
# Set columns in table
__PACKAGE__->add_column(
    qw/
        pool_id 
        exp_id
        sample_id
        cell_num
        matrix_index
        result
        measure_id
    /
);
# Set the primary key for the table
__PACKAGE__->set_primary_key(qw/measure_id/);

__PACKAGE__->has_many(readings => 'EpitopeDB::reading', 'measure_id');

# one to manay relationship between pool and pool_response
__PACKAGE__->belongs_to(pool => 'EpitopeDB::pool', 'pool_id');

# one to manay relationship between experiment and pool_response
__PACKAGE__->belongs_to(experiment => 'EpitopeDB::experiment', 'exp_id');

# one to manay relationship between sample and pool_response
__PACKAGE__->belongs_to(sample => 'EpitopeDB::sample', 'sample_id');

# relationship between pool_response and pool_response_corravg
__PACKAGE__->might_have(pool_response_corravg => 'EpitopeDB::pool_response_corravg', 'measure_id');

#__PACKAGE__->has_one(measurement => 'EpitopeDB::measurement', 'measure_id');

=head1 NAME

EpitopeDB::hla - A model object representing a hla type.

=head1 DESCRIPTION

This is an object that represents a row in the 'gene' table of viroverse database.
It uses DBIx::Class (aka, DBIC) to do ORM. For Catalyst, this is designed to be 
used through Viroverse::Model::EpitopeDB. offline utilities may wish to use this 
class directly.

=cut

1;
