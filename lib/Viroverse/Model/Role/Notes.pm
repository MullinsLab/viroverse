use strict;
use warnings;

package Viroverse::Model::Role::Notes;
use Viroverse::Model::note;
use Moo::Role;
use namespace::autoclean;

=head1 NAME

Viroverse::Model::Role::Notes - common methods for handling notes on a record

=head1 REQUIRES

=head2 vv_uid

=cut

requires 'vv_uid';

=head1 PROVIDES

=head2 notes

Returns a list of L<Viroverse::Model::note> objects for this record.

Nota bene: This method does I<not> consider the record's own C<note> column if
it exists.

=cut

sub notes {
    my $self  = shift;
    my @notes = Viroverse::Model::note->search_where({ vv_uid => $self->vv_uid });
    return @notes;
}

=head2 add_note

Creates a new L<Viroverse::Model::note> object for this record.

Takes a hashref which is passed to L<Viroverse::Model::note/insert>.  Returns
the newly created object.

=cut

sub add_note {
    my ($self, $data) = @_;
    return Viroverse::Model::note->insert({
        %$data,
        vv_uid => $self->vv_uid,
    });
}

1;
