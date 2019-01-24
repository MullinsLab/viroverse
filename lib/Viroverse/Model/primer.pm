package Viroverse::Model::primer;
use base 'Viroverse::CDBI';
use Viroverse::Model::pcr;
use Viroverse::Logger qw< :log :dlog >;
use ViroDB;
use 5.018;
use strict;

use overload
    'cmp' => 'compare_to';

__PACKAGE__->table('viroserve.primer');
__PACKAGE__->sequence('viroserve.primer_primer_id_seq');
__PACKAGE__->columns(Essential =>
   qw[
        primer_id
        name
        orientation
        lab_common
        organism_id
        ]
);
__PACKAGE__->columns(Others =>
        qw[
        sequence
        some_number
        vv_uid
      ]
);

__PACKAGE__->has_many(pcr_products => ['Viroverse::Model::pcr_primer', 'pcr_product_id']);
__PACKAGE__->has_many(rt_products => ['Viroverse::Model::rt_primer', 'rt_product_id']);

sub organism {
    my $self = shift;
    return undef unless $self->organism_id;
    return ViroDB->instance->resultset("Organism")->find( $self->organism_id );
}

sub positions {
    my $self = shift;
    my $primer = ViroDB->instance->resultset("Primer")->single(
        { name => $self->name, sequence => $self->seq }
    );
    return unless $primer;
    return $primer->positions;
}

sub accessor_name_for {
    my ($class, $column) = @_;

    # sequence clashes with the PK sequence accessor for CDBI
    return 'seq' if $column eq 'sequence';
    return $column;
}

sub to_string {
    my $self = shift;

    return $self->name;
}

sub compare_to {
    my ($self, $other, $swap) = @_;
    if ($swap) {
        ($self, $other) = ($other, $self);
    }
    return ($self->orientation cmp $other->orientation) || (fc($self->name) cmp fc($other->name));
}

sub list {
    my ($pkg,$start) = @_;
    my @objs;

    if ($start) {
        @objs = Viroverse::Model::primer->search_ilike( name => "$start%" );
    } else {
        @objs = Viroverse::Model::primer->retrieve_all();
    }

    return map { {primer_id => $_->primer_id, name => $_->name, orientation => $_->orientation, lab_common => $_->lab_common} } @objs ;
}

1;
