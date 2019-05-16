package Viroverse::Model::EpitopeDB;

use strict;
use base 'Catalyst::Model::DBIC::Schema';

require Viroverse::Config;
__PACKAGE__->config(
    schema_class => 'EpitopeDB',
    connect_info => {
        dsn         => Viroverse::Config->conf->{dsn},
        user        => Viroverse::Config->conf->{read_only_user},
        password    => Viroverse::Config->conf->{read_only_pw},

        pg_enable_utf8  => 1,
        on_connect_do   => [
            "SET TIME ZONE 'UTC'",
        ],
    },
);

=head1 NAME

Viroverse::Model::EpitopeDB - Catalyst DBIC Schema Model
=head1 SYNOPSIS

See L<Viroverse>

=head1 DESCRIPTION

L<Catalyst::Model::DBIC::Schema> Model using schema L<EpitopeDB>

=head1 AUTHOR

Wenjie Deng

=cut

1;
