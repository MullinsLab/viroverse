package Viroverse::Model::EpitopeDB;

use strict;
use base 'Catalyst::Model::DBIC::Schema';

require Viroverse::config;
__PACKAGE__->config(
    schema_class => 'EpitopeDB',
    connect_info => {
        dsn         => $Viroverse::config::dsn,
        user        => $Viroverse::config::read_only_user,
        password    => $Viroverse::config::read_only_pw,

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

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
