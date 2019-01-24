package EpitopeDB::epitope_mutant;

use base qw/DBIx::Class/;

# Load required DBIC stuff
__PACKAGE__->load_components(qw/PK::Auto Core/);
# Set the table name
__PACKAGE__->table('epitope.epitope_mutant');
# Set columns in table
__PACKAGE__->add_column(qw/epit_id mutant_id patient_id note/);
# Set the primary key for the table
__PACKAGE__->set_primary_key(qw/epit_id mutant_id patient_id/);

__PACKAGE__->belongs_to(epitope => 'EpitopeDB::epitope', 'epit_id');
__PACKAGE__->belongs_to(mutant => 'EpitopeDB::mutant', 'mutant_id');
__PACKAGE__->belongs_to(sample => 'EpitopeDB::sample', 'patient_id');


=head1 NAME

EpitopeDB::hla - A model object representing a hla type.

=head1 DESCRIPTION

This is an object that represents a row in the 'gene' table of viroverse database.
It uses DBIx::Class (aka, DBIC) to do ORM. For Catalyst, this is designed to be 
used through Viroverse::Model::EpitopeDB. offline utilities may wish to use this 
class directly.

=cut

1;
