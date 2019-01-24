package Viroverse::Model::pcr::cleanup;
use base 'Viroverse::CDBI';
__PACKAGE__->table('viroserve.pcr_cleanup');
__PACKAGE__->sequence('viroserve.pcr_cleanup_pcr_cleanup_id_seq');
__PACKAGE__->columns(All =>
   qw[
        pcr_cleanup_id
        pcr_product_id
        protocol_id
        final_conc
        final_conc_unit_id
        scientist_id
        date_completed
        notes
    ]
);

__PACKAGE__->has_a(scientist_id => 'Viroverse::Model::scientist');
__PACKAGE__->has_a(pcr_product_id => 'Viroverse::Model::pcr');
__PACKAGE__->has_a(protocol_id => 'Viroverse::Model::protocol');

sub to_string {
    my $self = shift;
    my $r;

    my $protocol = $self->protocol_id;

    if ($protocol and $protocol->protocol_type_id) {
        my $type = $protocol->protocol_type_id->name;
        my $verb = $type eq 'purification'  ?     'purified' :
                   $type eq 'concentration' ? 'concentrated' :
                                                          '' ;
        $r = $protocol->name . " $verb";
    }

    if ($self->final_conc) {
        $r .= " (".$self->final_conc.") nM";
    }

    return $r
}

1;
