package Viroverse::Model::na_sequence_alignment_pairwise;
use base 'Viroverse::CDBI';
use strict;
use Viroverse::Model::alignment;
use Viroverse::Model::na_sequence_alignment;

__PACKAGE__->table('viroserve.na_sequence_alignment_pairwise');
__PACKAGE__->columns(Primary => qw[alignment_id alignment_revision alignment_taxa_revision sequence_start reference_start]);
__PACKAGE__->columns(Essential => qw[sequence_end reference_end]);

# XXX: Is this dicey because alignment_id is part of the PK?  Not sure!
# -trs, 15 Nov 2013
# __PACKAGE__->has_a(alignment_id => 'Viroverse::Model::alignment');
sub alignment_id {
    my $self = shift;
    return Viroverse::Model::alignment->retrieve(
        $self->get('alignment_id'),
        $self->alignment_revision,
        $self->alignment_taxa_revision
    );
}

# __PACKAGE__->has_many(sequences => ['Viroverse::Model::na_sequence_alignment' => 'na_sequence_id']);
sub sequences {
    my $self = shift;
    my @aligned = Viroverse::Model::na_sequence_alignment->search_where(
        { map {; $_ => $self->$_ }
            qw( alignment_id alignment_revision alignment_taxa_revision ) },
        { order_by => "na_sequence_id, na_sequence_revision DESC" },
    );
    return map $_->na_sequence_id, @aligned;
}

1;
