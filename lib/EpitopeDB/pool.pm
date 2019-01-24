package EpitopeDB::pool;

use base qw/DBIx::Class/;

# Load required DBIC stuff
__PACKAGE__->load_components(qw/PK::Auto Core/);
# Set the table name
__PACKAGE__->table('epitope.pool');
# Set columns in table
__PACKAGE__->add_column(
    qw/
        pool_id 
        name 
    /
);
# Set the primary key for the table
__PACKAGE__->set_primary_key(qw/pool_id/);

# many to many relationship between pool and peptide
__PACKAGE__->has_many(pool_pept => 'EpitopeDB::pool_pept', 'pool_id');
__PACKAGE__->many_to_many(peptides => 'pool_pept', 'peptide');

# one to manay relationship between pool and pool_response
__PACKAGE__->has_many(pool_response => 'EpitopeDB::pool_response', 'pool_id');

# one to manay relationship between pool and pool_response_corravg
__PACKAGE__->has_many(pool_response_corravg => 'EpitopeDB::pool_response_corravg', 'pool_id');


sub list_names {
    my ($start) = @_;
    my $schema = EpitopeDB->connect($Viroverse::config::dsn, $Viroverse::config::read_only_user,$Viroverse::config::read_only_pw);
    my @objs;
    if ($start) {
        $start = uc $start;
        @objs = $schema->resultset('EpitopeDB::pool')->search_like( name => "$start%", {order_by=>'name'} );
    } else {
#        @objs = EpitopeDB::peptide->retrieve_all_sorted_by('name');
    }

    return {map {$_->pool_id => { pool_id => $_->pool_id, name => $_->name }} @objs} ;
}

=head1 NAME

EpitopeDB::hla - A model object representing a hla type.

=head1 DESCRIPTION

This is an object that represents a row in the 'gene' table of viroverse database.
It uses DBIx::Class (aka, DBIC) to do ORM. For Catalyst, this is designed to be 
used through Viroverse::Model::EpitopeDB. offline utilities may wish to use this 
class directly.

=cut

1;
