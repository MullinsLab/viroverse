package Viroverse::Model::na_sequence_alignment;
use base 'Viroverse::CDBI';
use strict;
use Viroverse::Model::alignment;
use Viroverse::Model::sequence::dna;

__PACKAGE__->table('viroserve.na_sequence_alignment');
__PACKAGE__->columns(Primary => qw[
    alignment_id
    alignment_revision
    alignment_taxa_revision
    na_sequence_id
    na_sequence_revision
]);
__PACKAGE__->columns(Other => qw[
    is_reference
    ]
);

# __PACKAGE__->has_a(alignment_id => 'Viroverse::Model::alignment');
sub alignment_id {
    my $self = shift;
    return Viroverse::Model::alignment->retrieve(
        $self->get('alignment_id'),
        $self->alignment_revision,
        $self->alignment_taxa_revision
    );
}

# __PACKAGE__->has_a(na_sequence_id => 'Viroverse::Model::sequence::dna');
sub na_sequence_id {
    my $self = shift;
    return Viroverse::Model::sequence::dna->retrieve( $self->get('na_sequence_id'), $self->na_sequence_revision );
}

1;
