package EpitopeDB::peptide;

use base qw/DBIx::Class::Schema/;

# Load required DBIC stuff
__PACKAGE__->load_components(qw/Core/);
# Set the table name
__PACKAGE__->table('epitope.peptide');
# Set columns in table
__PACKAGE__->add_columns(
    qw/
        pept_id 
        name 
        sequence 
        origin_id 
        gene_id 
        position_hxb2_start 
        position_hxb2_end
        position_auto_start
        position_auto_end
        position_align_start
        position_align_end
        /
);
# Set the primary key for the table
__PACKAGE__->set_primary_key('pept_id');

__PACKAGE__->has_many(pept_responses => 'EpitopeDB::pept_response', 'pept_id');
__PACKAGE__->has_many(pept_response_corravg => 'EpitopeDB::pept_response_corravg', 'pept_id');
__PACKAGE__->has_many(titrations => 'EpitopeDB::titration', 'pept_id');
__PACKAGE__->has_many(hla_responses => 'EpitopeDB::hla_response', 'pept_id');
#__PACKAGE__->has_many(pool_responses => 'EpitopeDB::pool_response', 'pept_id');

__PACKAGE__->might_have(epitope => 'EpitopeDB::epitope', 'pept_id');

__PACKAGE__->belongs_to(gene => 'EpitopeDB::gene', 'gene_id');
__PACKAGE__->belongs_to(origin => 'EpitopeDB::origin', 'origin_id');

__PACKAGE__->has_many(hla_pept => 'EpitopeDB::hla_pept', 'pept_id');
__PACKAGE__->many_to_many(hlas => 'hla_pept', 'hla');

# many to many relationship between peptide and pool
__PACKAGE__->has_many(pool_pept => 'EpitopeDB::pool_pept', 'pept_id');
__PACKAGE__->many_to_many(pools => 'pool_pept', 'pool');

#__PACKAGE__->might_have(mutant => 'EpitopeDB::mutant', {'foreign.pept_id' => 'self.pept_id'});

sub list_names {
    my ($start) = @_;
    my $schema = EpitopeDB->connect($Viroverse::config::dsn, $Viroverse::config::read_only_user,$Viroverse::config::read_only_pw);
    my @objs;
    if ($start) {
        $start = uc $start;
        @objs = $schema->resultset('EpitopeDB::peptide')->search_like( name => "$start%", {order_by=>'name'} );
    } else {
#        @objs = EpitopeDB::peptide->retrieve_all_sorted_by('name');
    }

    return {map {$_->pept_id => { pept_id => $_->pept_id, name => $_->name }} @objs} ;
}

sub list_seqs {
    my ($start) = @_;
    my $schema = EpitopeDB->connect($Viroverse::config::dsn, $Viroverse::config::read_only_user,$Viroverse::config::read_only_pw);
    my @objs;
    if ($start) {
        $start = uc $start;
        @objs = $schema->resultset('EpitopeDB::peptide')->search_like( sequence => "$start%", {order_by=>'sequence'} );
    } else {
#        @objs = EpitopeDB::peptide->retrieve_all_sorted_by('name');
    }

    return {map {$_->pept_id => { pept_id => $_->pept_id, sequence => $_->sequence }} @objs} ;
}


=head1 NAME

EpitopeDB::hla - A model object representing a hla type.

=head1 DESCRIPTION

This is an object that represents a row in the 'gene' table of viroverse database.
It uses DBIx::Class (aka, DBIC) to do ORM. For Catalyst, this is designed to be 
used through Viroverse::Model::EpitopeDB. offline utilities may wish to use this 
class directly.

=cut

1;
