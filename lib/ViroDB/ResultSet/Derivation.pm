use strict;
use warnings;

package ViroDB::ResultSet::Derivation;
use base 'ViroDB::ResultSet';

sub create_with_default_outputs {
    my ($self, $args) = @_;
    my $txn = $self->result_source->schema->txn_scope_guard;
    my $new_derivation = $self->create({ %$args });
    for my $tissue_type ($new_derivation->protocol->output_tissue_types) {
        $new_derivation->output_samples->create({
            tissue_type => $tissue_type,
        });
    };
    $txn->commit;
    return $new_derivation;
}

1;
