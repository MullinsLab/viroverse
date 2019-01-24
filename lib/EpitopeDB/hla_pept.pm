package EpitopeDB::hla_pept;

use base qw/DBIx::Class/;

# Load required DBIC stuff
__PACKAGE__->load_components(qw/PK::Auto Core/);
# Set the table name
__PACKAGE__->table('epitope.hla_pept');
# Set columns in table
__PACKAGE__->add_column(qw/hla_id pept_id/);
# Set the primary key for the table
__PACKAGE__->set_primary_key(qw/hla_id pept_id/);

__PACKAGE__->belongs_to(hla => 'EpitopeDB::hla', 'hla_id');
__PACKAGE__->belongs_to(peptide => 'EpitopeDB::peptide', 'pept_id');

__PACKAGE__->might_have(prc_hp_hla => 'EpitopeDB::hla', {'foreign.hla_id' => 'self.hla_id'});


=head1 NAME

EpitopeDB::hla - A model object representing a hla type.

=head1 DESCRIPTION

This is an object that represents a row in the 'gene' table of viroverse database.
It uses DBIx::Class (aka, DBIC) to do ORM. For Catalyst, this is designed to be 
used through Viroverse::Model::EpitopeDB. offline utilities may wish to use this 
class directly.

=cut

1;
