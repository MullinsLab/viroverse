package EpitopeDB::hla_response;

use base qw/DBIx::Class/;

# Load required DBIC stuff
__PACKAGE__->load_components(qw/PK::Auto Core/);
# Set the table name
__PACKAGE__->table('epitope.hla_response');
# Set columns in table
__PACKAGE__->add_column(
    qw/
        pept_id 
        exp_id
        sample_id
        blcl_id
        cell_num
        result
        measure_id
        /
);
# Set the primary key for the table
__PACKAGE__->set_primary_key(qw/measure_id/);

__PACKAGE__->has_many(readings => 'EpitopeDB::reading', 'measure_id');

__PACKAGE__->belongs_to(peptide => 'EpitopeDB::peptide', 'pept_id');
__PACKAGE__->belongs_to(experiment => 'EpitopeDB::experiment', 'exp_id');
__PACKAGE__->belongs_to(sample => 'EpitopeDB::sample', 'sample_id');
__PACKAGE__->belongs_to(blcl => 'EpitopeDB::blcl', 'blcl_id');


__PACKAGE__->might_have(hla_response_corravg => 'EpitopeDB::hla_response_corravg', 'measure_id');
__PACKAGE__->might_have(hr_sample => 'EpitopeDB::sample', {'foreign.sample_id' => 'self.sample_id'});

=head1 NAME

EpitopeDB::hla - A model object representing a hla type.

=head1 DESCRIPTION

This is an object that represents a row in the 'gene' table of viroverse database.
It uses DBIx::Class (aka, DBIC) to do ORM. For Catalyst, this is designed to be 
used through Viroverse::Model::EpitopeDB. offline utilities may wish to use this 
class directly.

=cut

1;
