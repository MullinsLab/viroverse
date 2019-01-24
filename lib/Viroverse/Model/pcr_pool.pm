package Viroverse::Model::pcr_pool;
use warnings;
use strict;
use base 'Viroverse::CDBI';
use List::UtilsBy qw< uniq_by >;
use Viroverse::Model::pcr;

__PACKAGE__->table('viroserve.pcr_pool');
__PACKAGE__->sequence('viroserve.pcr_pool_pcr_pool_id_seq');
__PACKAGE__->columns(All =>
   qw[
        pcr_pool_id
        date_completed
        date_entered
        scientist_id
        notes
        vv_uid
    ]
);

__PACKAGE__->has_a(scientist_id => 'Viroverse::Model::scientist');
__PACKAGE__->has_many(pcr_products => 'Viroverse::Model::pcr_pool_pcr_product');

sub to_string {
       my $self = shift;
       return Viroverse::Model::pcr->fetchFromPoolID($self->pcr_pool_id())->to_string();
}

sub primers {
    my $self = shift;
    die "Tried to set primers on a PCR pool; this isn't a real relationship"
        if @_;

    return uniq_by { $_->primer_id }
               map { $_->primers }
               map { $_->pcr_product_id}
                   $self->pcr_products;
}

# Recall that this can't delegate to `primers` because each pooled product needs
# to establish the proper positions of its own primers. Not that it's clear what
# it would mean if different products in a pool being sequenced had a variety of
# primers.
sub primers_with_proper_positions {
    my $self = shift;
    return [
        uniq_by { $_->{primer}->primer_id }
            map { @{$_->primers_with_proper_positions} }
            map { $_->pcr_product_id }
                $self->pcr_products
    ];
}

1;
