package EpitopeDB::gene;

use base qw/DBIx::Class/;

# Load required DBIC stuff
__PACKAGE__->load_components(qw/PK::Auto Core/);
# Set the table name
__PACKAGE__->table('epitope.gene');
# Set columns in table
__PACKAGE__->add_column(
    qw/    gene_id
        gene_name
        hxb2_start 
        hxb2_end
    /
);
# Set the primary key for the table
__PACKAGE__->set_primary_key(qw/gene_id/);

__PACKAGE__->has_many(peptides => 'EpitopeDB::peptide', 'gene_id');

=head1 NAME

EpitopeDB::gene - A model object representing a gene.

=head1 DESCRIPTION

This is an object that represents a row in the 'gene' table of viroverse database.
It uses DBIx::Class (aka, DBIC) to do ORM. For Catalyst, this is designed to be 
used through Viroverse::Model::EpitopeDB. offline utilities may wish to use this 
class directly.

=cut

1;
