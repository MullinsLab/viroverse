package Viroverse::Model::chromat_type;
use base 'Viroverse::CDBI';
use strict;

__PACKAGE__->table('viroserve.chromat_type');
__PACKAGE__->sequence('viroserve.chromat_type_chromat_type_id_seq');
__PACKAGE__->columns(All =>
    qw[
        chromat_type_id
        ident_string
        name
        date_added
        ]
);

sub get_hashref {
    my $pkg = shift;
    my @all = $pkg->retrieve_all;
    return { map { $_->name => $_->chromat_type_id  } @all };
}

1;
