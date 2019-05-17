package Viroverse::CDBI;
use base 'Class::DBI::Pg';
use Class::DBI::AbstractSearch;
use Class::DBI::Plugin::RetrieveAll;
use Carp 'croak';
use Viroverse::Config;
use Viroverse::CDBI::TxnScopeGuard;
use Data::Dumper;
use strict;

# This is just here to be inherited from by table-specific objects

our $is_not_null = 'is not null';
our $is_null = 'is null';
sub is_null { $is_null };
sub is_not_null { $is_not_null };

__PACKAGE__->connection(Viroverse::Config->conf->{dsn},Viroverse::Config->conf->{read_write_user},Viroverse::Config->conf->{read_write_pw});
__PACKAGE__->db_Main->{AutoCommit} = 1;
__PACKAGE__->autoupdate(1);

## below pasted from http://lists.digitalcraftsmen.net/pipermail/classdbi/2005-October/000338.html
## in order to make CDBI connections thread-friendly under mod_perl
sub _mk_db_closure {
        my ($class, $dsn, $user, $pass, $attr) = @_;

        $attr ||= {};
        my $dbh;
        my $process_id = $$;
        return sub {
                # set the PID in a private cache key to prevent us
                # from sharing one with the parent after fork.  This
                # is better than disconnecting the existing $dbh since
                # the parent may still need the connection open.  Note
                # that forking code also needs to set InactiveDestroy
                # on all open handles in the child or the connection
                # will be broken during DESTROY.
                $attr->{private_cache_key_pid} = $$;

                # reopen if this is a new process or if the connection
                # is bad
                if ($process_id != $$ or not ($dbh && $dbh->FETCH('Active') && $dbh->ping)) {
                    $dbh = DBI->connect_cached($dsn, $user, $pass, $attr);
                            $dbh->{AutoCommit} = 1;
                    $process_id = $$;
                }
                return $dbh;
        };

}

sub search_ilike { shift->_do_search(ILIKE => @_) };

sub get_id {
    my $self = shift;

    return (join '.',$self->id);
}


=item Viroverse::CDBI->shorthand()

Returns the last package part (everything after the last C<::>) of the blessed
object or class it is called on.  For example, returns "gel_lane" for
"Viroverse::Model::gel_lane".

=cut

sub shorthand {
    my $pkg = ref($_[0]) || $_[0];
    return $pkg =~ s/^.+:://r;
}

=item Viroverse::CDBI->longhand()
    meant to be overridden by classes whose attributes require mre detail than the package name.
    Returns the shorthand name by default.  Any package which overrides it will call this then append any additional name
    with a dot (.)
    e.g.  Viroverse.Model.extraction will override this, call the SUPER function, then append the extraction product type to the end
    (so a dna extraction product would return extraction.dna)
=cut
sub longhand {
    my $self = shift;
    return $self->shorthand();
}

*give_id = *get_id;

sub retrieve_many {
    my $pkg = shift;

    my @pks =  $pkg->columns('Primary');
    croak "$pkg must declare single primary key to use retrieve_many " if @pks > 1;

    # Stringify Class::DBI::Column objects, but also work with plain strings.
    my $pk = "$pks[0]";

    my @ids = @_;
    my $binds = join(',',(map {'?'} @ids));

    my @objs = $pkg->search_where(
        $pk => { -in => [@ids] } #AbstractSearch will parameterize
    );

    return @objs;
}


sub search_single {
    my ($pkg,$value,$col) = @_;
    croak "Incorrect arguments:".join(',',@_) unless $pkg and $value;
    $col ||= 'name';
    croak "No such column $col" unless $pkg->find_column($col);

    my @matches = $pkg->search({$col => $value});
    if (@matches ==1) {
        return $matches[0];
    }

    return undef;
}

sub qualified_columns {
    my ($pkg,$grp) = @_;
    $grp ||= 'Essential';
    my $columns = join ",",map {$pkg->table.'.'.$_} $pkg->columns($grp);
}

=head2 txn_scope_guard

Returns a L<Viroverse::CDBI::TxnScopeGuard> object for L</db_Main>.

Intended to function similarly to L<DBIx::Class::Storage::TxnScopeGuard>.

=cut

sub txn_scope_guard {
    Viroverse::CDBI::TxnScopeGuard->new( dbh => shift->db_Main )
}

1;
