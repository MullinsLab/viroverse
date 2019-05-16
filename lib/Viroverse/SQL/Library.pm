use strict;
use warnings;
use utf8;
use 5.018;

package Viroverse::SQL::Library;
use Moose;
use Path::Tiny;
use Type::Params qw< compile Invocant >;
use Types::Standard qw< :types slurpy >;
use Template::Alloy;
use Viroverse::Config;
use namespace::autoclean;

has path => (
    is       => 'ro',
    isa      => InstanceOf['Path::Tiny'],
    default  => sub { path($ENV{VIROVERSE_ROOT})->child("sql/library") },
);

sub sql {
    my ($self, $name) = @_;
    my $file = $self->path->child("$name.sql");
    return $file->slurp_utf8;
}

sub pcr_ancestors {
    state $params = compile(
        Invocant,
        slurpy Dict[pcrs      => ArrayRef[Int]]
             | Dict[gel_lanes => ArrayRef[Int]]
    );
    my ($self, $args) = $params->(@_);

    my $sql = $self->sql("pcr_ancestors");
       $sql = $self->_fill($sql, $args);

    return $sql;
}

sub _fill {
    my ($self, $source, $args) = @_;
    $args = $args || {};

    state $template = Template::Alloy->new(
        START_TAG => '<%',
        END_TAG   => '%>',
    );
    my $filled = "";
    $template->process_simple(\$source, $args, \$filled)
        or die $template->error;
    return $filled;
}

__PACKAGE__->meta->make_immutable;
1;
