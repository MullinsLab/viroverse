package Viroverse::Model::unit;
use base 'Viroverse::CDBI';

use Physics::Unit qw( GetUnit InitUnit DeleteNames );
use Physics::Unit::Scalar qw( ScalarFactory );

__PACKAGE__->table('viroserve.unit');

__PACKAGE__->columns(All => qw[
    unit_id
    name
    ]
);

sub as_physics_unit {
    my $self = shift;
    return GetUnit($self->name);
}

sub with_magnitude {
    my ($self, $magnitude) = @_;
    my $unit_expr = $magnitude . " " . $self->name;
    return ScalarFactory($unit_expr);
}

DeleteNames(['g']);
InitUnit(['g']  => '1 gram');
InitUnit(['ng'] => '1 nanogram');
InitUnit(['mm'] => '1 millimeter');
InitUnit(['ul'] => '1 microliter');
InitUnit(['cells','pellet','dil','copies'] => '1');

1;
