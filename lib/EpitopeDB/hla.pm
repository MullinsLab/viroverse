package EpitopeDB::hla;

use base qw/DBIx::Class/;

# Load required DBIC stuff
__PACKAGE__->load_components(qw/PK::Auto Core/);
# Set the table name
__PACKAGE__->table('epitope.hla');
# Set columns in table
__PACKAGE__->add_column(qw/hla_id type hla_genotype_id/);
# Set the primary key for the table
__PACKAGE__->set_primary_key(qw/hla_id/);

__PACKAGE__->has_many(hla_pept => 'EpitopeDB::hla_pept', 'hla_id');
__PACKAGE__->many_to_many(peptides => 'hla_pept', 'peptide');


=head1 NAME

EpitopeDB::hla - A model object representing a hla type.

=head1 DESCRIPTION

This is an object that represents a row in the 'gene' table of viroverse database.
It uses DBIx::Class (aka, DBIC) to do ORM. For Catalyst, this is designed to be 
used through Viroverse::Model::EpitopeDB. offline utilities may wish to use this 
class directly.

=cut

1;
