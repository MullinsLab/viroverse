package EpitopeDB::epitope;

use base qw/DBIx::Class/;

# Load required DBIC stuff
__PACKAGE__->load_components(qw/PK::Auto Core/);
# Set the table name
__PACKAGE__->table('epitope.epitope');
# Set columns in table
__PACKAGE__->add_column(
    qw/
        epit_id
        pept_id 
        source_id
    /
);
# Set the primary key for the table
__PACKAGE__->set_primary_key(qw/epit_id/);

__PACKAGE__->has_one(peptide => 'EpitopeDB::peptide', {'foreign.pept_id' => 'self.pept_id'});

__PACKAGE__->belongs_to(source => 'EpitopeDB::source', 'source_id');

__PACKAGE__->has_many(epitope_mutant => 'EpitopeDB::epitope_mutant', 'epit_id');
__PACKAGE__->many_to_many(mutants => 'epitope_mutant', 'mutant');

__PACKAGE__->might_have(pept_response_corravg => 'EpitopeDB::pept_response_corravg', {'foreign.pept_id' => 'self.pept_id'});


=head1 NAME

EpitopeDB::hla - A model object representing a hla type.

=head1 DESCRIPTION

This is an object that represents a row in the 'gene' table of viroverse database.
It uses DBIx::Class (aka, DBIC) to do ORM. For Catalyst, this is designed to be 
used through Viroverse::Model::EpitopeDB. offline utilities may wish to use this 
class directly.

=cut

1;
