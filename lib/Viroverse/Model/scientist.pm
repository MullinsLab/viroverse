package Viroverse::Model::scientist;
use base 'Viroverse::CDBI';
use Carp qw[croak];
use strict;

__PACKAGE__->table('viroserve.scientist');
__PACKAGE__->sequence('viroserve.scientist_scientist_id_seq');
__PACKAGE__->columns(All =>
   qw[
        scientist_id
        name
        start_date
        end_date
        phone
        username
        email
        role
      ]
);

__PACKAGE__->add_constructor( search_by_username => 'username = ? ORDER BY scientist_id' );
__PACKAGE__->add_constructor( search_by_name     => 'name     = ? ORDER BY scientist_id' );

sub retrieve_by_username { shift->_retrieve_by('username', @_) }
sub retrieve_by_name     { shift->_retrieve_by('name', @_) }

sub _retrieve_by {
    my ($self, $by, $user) = @_;
    unless ($user) {
        Carp::cluck("No user passed to ", __PACKAGE__, "->retrieve_by_$by; very likely an error");
        return;
    }
    my @scientists = $self->can("search_by_$by")->($self, $user)
        or return;

    my $scientist = shift @scientists;
    Carp::carp("More than one scientist found with $by '$user'.  Using first, but this is dangerous!")
        if @scientists;

    return $scientist;
}

sub is_supervisor {
    my $self = shift;
    return $self->role eq "supervisor";
}

sub is_admin {
    my $self = shift;
    return $self->role eq "admin";
}

sub is_retired {
    my $self = shift;
    return $self->role eq "retired";
}

sub list {
    #get rid of pkg
    if ($_[0] eq __PACKAGE__) {
        shift;
    }
    my $start = shift;

    my @objs;
    if ($start) {
        @objs = __PACKAGE__->search_ilike( name => "$start%", {order_by=>'name'} );
    } else {
        @objs = __PACKAGE__->retrieve_all_sorted_by('name');
    }

    return map { {scientist_id => $_->scientist_id, name => $_->name } } @objs ;
}

sub to_hash {
    my $self = shift;
    return {
        id          => $self->id,
        username    => $self->username,
        name        => $self->name,
        email       => $self->email,
    };
}

sub TO_JSON { shift->to_hash }

1;
