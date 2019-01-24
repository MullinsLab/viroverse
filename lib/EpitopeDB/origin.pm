package EpitopeDB::origin;

use base qw/DBIx::Class/;

# Load required DBIC stuff
__PACKAGE__->load_components(qw/PK::Auto Core/);
# Set the table name
__PACKAGE__->table('epitope.origin');
# Set columns in table
__PACKAGE__->add_column(
    qw/    origin_id
        name
        na_sequence_id 
        na_sequence_revision
    /
);
# Set the primary key for the table
__PACKAGE__->set_primary_key(qw/origin_id/);

__PACKAGE__->has_many(peptides => 'EpitopeDB::peptide', 'origin_id');

=head1 NAME

EpitopeDB::gene - A model object representing a gene.

=head1 DESCRIPTION

This is an object that represents a row in the 'gene' table of viroverse database.
It uses DBIx::Class (aka, DBIC) to do ORM. For Catalyst, this is designed to be 
used through Viroverse::Model::EpitopeDB. offline utilities may wish to use this 
class directly.

=cut

1;
