use utf8;
package ViroDB;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use Moose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces(
    default_resultset_class => "ResultSet",
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2017-08-11 15:11:37
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:rM5oOsBHZUlpjpIor9M/SA

use strict;
use warnings;
use 5.018;

sub default_connection_info {
    require Viroverse::Config;
    return {
        dsn         => Viroverse::Config->conf->{dsn},
        user        => Viroverse::Config->conf->{read_write_user},
        password    => Viroverse::Config->conf->{read_write_pw},

        auto_savepoint  => 1,
        pg_enable_utf8  => 1,
        on_connect_do   => [
            "SET TIME ZONE 'UTC'",
        ],
    };
}

sub connect_default {
    my $self = shift;
    return $self->connect( $self->default_connection_info );
}

sub instance {
    my $self = shift;
    state $instance = $self->connect_default;
    return $instance;
}

__PACKAGE__->meta->make_immutable;
1;
