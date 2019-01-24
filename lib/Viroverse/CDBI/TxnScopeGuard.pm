use 5.018;
use strict;
use warnings;

package Viroverse::CDBI::TxnScopeGuard {
    use Moo;
    use Types::Standard qw< :types >;
    use namespace::clean;

    has dbh => (
        required => 1,
        is       => 'ro',
        isa      => InstanceOf['DBI::db'],
    );

    has inactivated => (
        is      => 'rwp',
        isa     => Bool,
        default => sub { 0 },
    );

    sub BUILD {
        my $self = shift;
        $self->dbh->begin_work;
    }

    sub DEMOLISH {
        my ($self, $global) = @_;
        return if $self->inactivated;

        warn "Rolling back transaction as guard went out of scope",
             ($global ? " in global destruction" : "");
        $self->rollback;
    }

    sub commit {
        my $self = shift;
        die "Commit already called on transaction scope guard"
            if $self->inactivated;
        $self->dbh->commit;
        $self->_set_inactivated(1);
    }

    sub rollback {
        my $self = shift;
        die "Rollback already called on transaction scope guard"
            if $self->inactivated;
        $self->dbh->rollback;
        $self->_set_inactivated(1);
    }
}

=head1 NAME

Viroverse::CDBI::TxnScopeGuard - Scoped DBI transactions

=head1 SYNOPSIS

    do {
        my $txn = Viroverse::CDBI->txn_scope_guard;
        ...
        $txn->commit;
    }

=head1 DESCRIPTION

Provides a guard object (a la L<Scope::Guard> or
L<DBIx::Class::Storage::TxnScopeGuard>) which wraps a L<DBI> transaction.  If
the transaction is not explicitly committed or rolled back, the transaction is
rolled back when the object goes out of scope and a warning is issued.

=head1 ATTRIBUTES

=head2 dbh

A L<DBI::db> object, such as that returned by L<Viroverse::CDBI/db_Main>.
Read-only.  Required.

=head2 inactivated

Boolean indicating if this guard has been inactivated by a previous commit or
rollback.  Read-only.

=head1 METHODS

=head2 commit

Commits the current transaction and inactivates the guard.

=head2 rollback

Rollsback the current transaction and inactivates the guard.

=cut

1;
