use strict;
use warnings;
use utf8;

package Viroverse::CachingFinder;
use Moo;
use Viroverse::Logger qw< :log >;
use Types::Standard -types;
use Types::Common::String qw< NonEmptySimpleStr >;

=head1 NAME

Viroverse::CachingFinder

=head1 SYNOPSIS

    my $finder = Viroverse::CachingFinder->new(
        resultset => ViroDB->instance->resultset("Scientist"),
        field     => "name",
    );
    my $sci = $finder->find("Evan Silberman");

=head1 DESCRIPTION

A CachingFinder is initialized with a L<DBIx::Class::ResultSet> object and a
L</field>, giving the name of a resultset column that can be used as a putative
key. Once initialized, calls to the L</find> method search the resultset for a
single row where the value of L</field> matches the argument of L</find>. The
L<DBIx::Class::Result> found is internally stored under the key used to look it
up; subsequent calls to L</find> with the same argument will not query the
database again.

=head1 ATTRIBUTES

=head2 resultset

An instance of L<DBIx::Class::ResultSet>. Required.

=cut

has 'resultset' => (
    is       => 'ro',
    isa      => InstanceOf['DBIx::Class::ResultSet'],
    required => 1,
);

=head2 field

A string naming a column of the L</resultset>. Required. Values of this column
should be unique in the database, at least in practice if not by constraint.

=cut

has 'field' => (
    is       => 'ro',
    isa      => NonEmptySimpleStr,
    required => 1,
);

has _storage => (
    is      => 'ro',
    isa     => HashRef,
    default => sub { {} },
);

=head1 METHODS

=head2 find

Given a value for L</field>, returns the memoized member of L</resultset> if
it's present in the instance's cache, otherwise looks it up using
L<DBIx::Class::ResultSet/search> otherwise and caches the resulting row under
the given value. Dies if no result is found by the search.

=cut

sub find {
    my ($self, $key) = @_;
    die "Key is required" unless defined $key;

    unless ($self->_storage->{$key}) {
        $self->_storage->{$key} = $self->resultset->search({ $self->field => $key })->single
            or die sprintf "Couldn't find a %s result where %s equals “%s”",
                           $self->resultset->result_class,
                           $self->field,
                           $key;
        log_debug {[
            "Memoized %s #%s for %s “%s”",
            $self->resultset->result_class,
            $self->_storage->{$key}->id,
            $self->field,
            $key
        ]};
    }

    return $self->_storage->{$key};
}

1;
