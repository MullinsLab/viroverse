package EpitopeDB::test_patient;

use base qw/DBIx::Class/;

# Load required DBIC stuff
__PACKAGE__->load_components(qw/PK::Auto Core/);
# Set the table name
__PACKAGE__->table('epitope.test_patient');
# Set columns in table
__PACKAGE__->add_column(
    qw/
        patient_id 
        patient
    /
);
# Set the primary key for the table
__PACKAGE__->set_primary_key(qw/patient_id/);

__PACKAGE__->has_many(samples => 'EpitopeDB::sample', {'foreign.patient_id' => 'self.patient_id'});
__PACKAGE__->has_many(epitope_mutants => 'EpitopeDB::epitope_mutant', 'patient_id');

__PACKAGE__->has_many(pept_response_corravgs => 'EpitopeDB::pept_response_corravg', {'foreign.patient_id' => 'self.patient_id'});
#__PACKAGE__->has_many(titration_corravgs => 'EpitopeDB::titration_corravg', {'foreign.patient_id' => 'self.patient_id'});
#__PACKAGE__->has_many(hla_response_corravgs => 'EpitopeDB::hla_response_corravg', {'foreign.patient_id' => 'self.patient_id'});


=head1 NAME

EpitopeDB::hla - A model object representing a hla type.

=head1 DESCRIPTION

This is an object that represents a row in the 'gene' table of viroverse database.
It uses DBIx::Class (aka, DBIC) to do ORM. For Catalyst, this is designed to be 
used through Viroverse::Model::EpitopeDB. offline utilities may wish to use this 
class directly.

=cut

1;
