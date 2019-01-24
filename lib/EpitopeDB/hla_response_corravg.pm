package EpitopeDB::hla_response_corravg;

use base qw/DBIx::Class/;

# Load required DBIC stuff
__PACKAGE__->load_components(qw/PK::Auto Core/);
# Set the table name
__PACKAGE__->table('epitope.hla_response_corravg');
# Set columns in table
__PACKAGE__->add_column(
    qw/
        measure_id
        bg_measure_id
        pept_id
        exp_id
        sample_id
        patient_id
        blcl_id
        avg
        corr_avg
    /
);
# Set the primary key for the table
__PACKAGE__->set_primary_key(qw/measure_id/);

__PACKAGE__->belongs_to(sample => 'EpitopeDB::sample', 'sample_id');

#__PACKAGE__->belongs_to(test_patient => 'EpitopeDB::test_patient', {'foreign.patient_id' => 'self.patient_id'});

=head1 NAME

EpitopeDB::hla - A model object representing a hla type.

=head1 DESCRIPTION

This is an object that represents a row in the 'gene' table of viroverse database.
It uses DBIx::Class (aka, DBIC) to do ORM. For Catalyst, this is designed to be 
used through Viroverse::Model::EpitopeDB. offline utilities may wish to use this 
class directly.

=cut

1;
