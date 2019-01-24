use strict;
use warnings;

package ViroDB::ResultSet::NucleicAcidSequence;
use base 'ViroDB::ResultSet';

=head1 NAME

ViroDB::ResultSet::NucleicAcidSequence - Additional resultset methods for sequences

=head1 METHODS

=head2 find_by_idrev

Takes a single sequence id or id.rev string and returns either the current
revision for that id or the explicitly specified revision.  If you already have
id and revision as separate parts, just use L<DBIx::Class::ResultSet/find>.

Returns a L<ViroDB::Result::NucleicAcidSequence> object, or undef on failure.

Note that the returned sequence revision may be marked deleted.

=cut

sub find_by_idrev {
    my ($self, $idrev) = @_;
    my ($id, $rev)     = split /\./, $idrev, 2;
    my $me             = $self->current_source_alias;

    # Either look up by specific revision…
    return $self->find($id, $rev)
        if defined $rev;

    # …or find the latest revision for the id.  The latest revision here may be
    # a deleted revision if all revisions are deleted.
    return $self->search({ "$me.na_sequence_id" => $id })
        ->order_by({ -desc => [ \["($me.deleted IS NOT TRUE)::int"], "$me.na_sequence_revision" ] })
        ->rows(1)
        ->first;
}


=head2 search_by_idrevs

Takes a list of id or id.rev strings and limits the current resultset to the
given sequences.  IDs without a revision specified will get the latest revision
for that sequence.  Note that if you don't specify a revision you'll never get
records returned for sequences where all revisions are marked deleted.  This is
in contrast to L</find_by_idrev>.

Returns a resultset or list of results, depending on calling context, the same
as L<DBIx::Class::ResultSet/search>.

=cut

sub search_by_idrevs {
    my ($self, @ids) = @_;
    my $me = $self->current_source_alias;

    # Turn all id.revs into search conditions, either for the specific revision
    # or the latest.
    my @conditions = map {
        my ($id, $rev) = split /\./, $_, 2;
        defined $rev
            ? { "$me.na_sequence_id" => $id, "$me.na_sequence_revision" => $rev }
            : { "$me.na_sequence_id" => $id, "maybe_latest_revision.na_sequence_revision" => { '!=', undef } };
    } @ids;

    return unless @conditions;
    return $self->search(
        \@conditions,
        { join => 'maybe_latest_revision' }
    );
}


=head2 latest_revisions

Restricts the current resultset to just the latest revisions of sequences.

Returns a resultset or list of results, depending on calling context, the same
as L<DBIx::Class::ResultSet/search>.

=cut

sub latest_revisions {
    my $self = shift;
    return $self->search({}, { join => 'latest_revision' });
}

sub with_type {
    my ($self, $proto) = @_;
    return $self->search({'type.name' => $proto}, {join =>  'type' });
}

sub non_genomic {
    my $self = shift;
    return $self->search({ 'type.name' => { '!=' => "Genomic" } },
                         { join => 'type' });
}

sub rollup_by_type {
    my $self = shift;
    my $me = $self->current_source_alias;
    $self->as_subselect_rs
         ->search(undef, { join => "type" })
         ->order_by("type.name")
         ->group_by("type.name")
         ->columns([ { sequence_type => 'type.name' }, { 'count' => { 'COUNT' => '*'} }]);
}

1;
