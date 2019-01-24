package EpitopeDB::pept_response_corravg;

use base qw/DBIx::Class/;

# Load required DBIC stuff
__PACKAGE__->load_components(qw/PK::Auto Core/);
# Set the table name
__PACKAGE__->table('epitope.pept_response_corravg');
# Set columns in table
__PACKAGE__->add_column(
    qw/    measure_id
        bg_measure_id
        pept_id
        exp_id
        patient_id
        sample_id
        avg 
        corr_avg
    /
);
# Set the primary key for the table
__PACKAGE__->set_primary_key(qw/measure_id/);

__PACKAGE__->has_one(pept_response => 'EpitopeDB::pept_response', 'measure_id');

__PACKAGE__->belongs_to(peptide => 'EpitopeDB::peptide', 'pept_id');
__PACKAGE__->belongs_to(sample => 'EpitopeDB::sample', 'sample_id');
__PACKAGE__->belongs_to(test_patient => 'EpitopeDB::test_patient', {'foreign.patient_id' => 'self.patient_id'});

__PACKAGE__->might_have(prc_titration => 'EpitopeDB::titration', {'foreign.pept_id' => 'self.pept_id', 'foreign.sample_id' => 'self.sample_id'});
__PACKAGE__->might_have(prc_titration_corravg => 'EpitopeDB::titration_corravg', {'foreign.pept_id' => 'self.pept_id', 'foreign.patient_id' => 'self.patient_id'});
__PACKAGE__->might_have(prc_hla_response_corravg => 'EpitopeDB::hla_response_corravg', {'foreign.pept_id' => 'self.pept_id', 'foreign.patient_id' => 'self.patient_id'});
__PACKAGE__->might_have(prc_hla_pept => 'EpitopeDB::hla_pept', {'foreign.pept_id' => 'self.pept_id'});
__PACKAGE__->might_have(prc_sample => 'EpitopeDB::sample', {'foreign.sample_id' => 'self.sample_id'});
__PACKAGE__->might_have(left_join_test_patient => 'EpitopeDB::test_patient', {'foreign.patient_id' => 'self.patient_id'});
=head1 NAME

EpitopeDB::gene - A model object representing a gene.

=head1 DESCRIPTION

This is an object that represents a row in the 'gene' table of viroverse database.
It uses DBIx::Class (aka, DBIC) to do ORM. For Catalyst, this is designed to be 
used through Viroverse::Model::EpitopeDB. offline utilities may wish to use this 
class directly.

=cut

1;
