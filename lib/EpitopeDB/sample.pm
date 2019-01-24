package EpitopeDB::sample;

use base qw/DBIx::Class/;

# Load required DBIC stuff
__PACKAGE__->load_components(qw/PK::Auto Core/);
# Set the table name
__PACKAGE__->table('epitope.sample');
# Set columns in table
__PACKAGE__->add_column(
    qw/
        sample_id 
        tissue
        sample_date
        patient
        patient_id
    /
);
# Set the primary key for the table
__PACKAGE__->set_primary_key(qw/sample_id/);

__PACKAGE__->has_many(pept_responses => 'EpitopeDB::pept_response', 'sample_id');
__PACKAGE__->has_many(pept_response_corravgs => 'EpitopeDB::pept_response_corravg', 'sample_id');
__PACKAGE__->has_many(titrations => 'EpitopeDB::titration', 'sample_id');
__PACKAGE__->has_many(titration_corravgs => 'EpitopeDB::titration_corravg', 'sample_id');
__PACKAGE__->has_many(hla_responses => 'EpitopeDB::hla_response', 'sample_id');
__PACKAGE__->has_many(hla_response_corravgs => 'EpitopeDB::hla_response_corravg', 'sample_id');

# one to manay relationship between sample and pool_response
__PACKAGE__->has_many(pool_response => 'EpitopeDB::pool_response', 'sample_id');

# one to manay relationship between sample and pool_response_corravg
__PACKAGE__->has_many(pool_response_corravg => 'EpitopeDB::pool_response_corravg', 'sample_id');

__PACKAGE__->has_many(epitope_mutants => 'EpitopeDB::epitope_mutant', {'foreign.patient_id' => 'self.patient_id'});

__PACKAGE__->belongs_to(test_patient => 'EpitopeDB::test_patient', {'foreign.patient_id' => 'self.patient_id'});



=head1 NAME

EpitopeDB::hla - A model object representing a hla type.

=head1 DESCRIPTION

This is an object that represents a row in the 'gene' table of viroverse database.
It uses DBIx::Class (aka, DBIC) to do ORM. For Catalyst, this is designed to be 
used through Viroverse::Model::EpitopeDB. offline utilities may wish to use this 
class directly.

=cut

1;
