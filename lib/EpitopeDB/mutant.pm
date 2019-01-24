package EpitopeDB::mutant;

use base qw/DBIx::Class/;

# Load required DBIC stuff
__PACKAGE__->load_components(qw/PK::Auto Core/);
# Set the table name
__PACKAGE__->table('epitope.mutant');
# Set columns in table
__PACKAGE__->add_column(
    qw/
        mutant_id
        pept_id
    /
);
# Set the primary key for the table
__PACKAGE__->set_primary_key(qw/mutant_id/);

__PACKAGE__->has_many(epitope_mutant => 'EpitopeDB::epitope_mutant', 'mutant_id');
__PACKAGE__->many_to_many(epitopes => 'epitope_mutant', 'epitope');

__PACKAGE__->has_one(peptide => 'EpitopeDB::peptide', {'foreign.pept_id' => 'self.pept_id'});



=head1 NAME

EpitopeDB::hla - A model object representing a hla type.

=head1 DESCRIPTION

This is an object that represents a row in the 'gene' table of viroverse database.
It uses DBIx::Class (aka, DBIC) to do ORM. For Catalyst, this is designed to be 
used through Viroverse::Model::EpitopeDB. offline utilities may wish to use this 
class directly.

=cut

1;
