use strict;
use warnings;
use utf8;
use 5.018;

package Viroverse::Import::RevisedSequences;
use Moo;
use Types::Standard -types;
use Viroverse::Logger qw< :log :dlog >;
use ViroDB;
use Viroverse::CachingFinder;
use Viroverse::Types -types;
use Types::Common::String qw< SimpleStr NonEmptySimpleStr >;
use List::Util 1.33 qw< any >;
use namespace::clean;

with 'Viroverse::Import';


=head1 DESCRIPTION

This importer is for creating new revisions of existing Viroverse sequences. It
simply looks up the sequence by ID and creates a new revision, with only those
fields mapped to the input file being updated in the new revision. If the
fields provided in the input row all match the latest revision of the sequence,
a new revision is not created.

=cut

has '+key_map' => (
    isa => Dict[
        na_sequence_id => NonEmptySimpleStr,
        name           => Optional[SimpleStr],
        sequence       => Optional[SimpleStr],
        na_type        => Optional[SimpleStr],
        scientist_name => Optional[SimpleStr],
        note           => Optional[SimpleStr],
    ],
);

has _scientists => (
    is      => 'ro',
    isa     => InstanceOf["Viroverse::CachingFinder"],
    default => sub { Viroverse::CachingFinder->new(
        resultset => ViroDB->instance->resultset("Scientist"),
        field     => "name",
    )},
);

sub suggested_column_for_key_pattern {
    my ($package, $key) = @_;
    return {
        name                => qr/sequence_name|name/i,
        sequence            => qr/sequence(?!.*?name)/i,
        scientist_name      => qr/scientist/i,
    }->{$key};
}

sub process_row {
    my ($self, $row) = @_;
    state $db = ViroDB->instance;

    my ($id, $rev) = split /\./, $row->{na_sequence_id};

    my $sequence = $db->resultset("NucleicAcidSequence")->search(
        { 'me.na_sequence_id' => $id },
        { join => "latest_revision" }
    )->single;

    die "Sequence " . $row->{na_sequence_id} . " is deleted or doesn't exist"
        unless $sequence;

    die sprintf "Requested idrev %s doesn't match latest idrev %s",
                $row->{na_sequence_id},
                $sequence->idrev
        if defined $rev && $rev != $sequence->na_sequence_revision;


    # Look up the scientist if required.
    my $scientist = $row->{scientist_name} &&
                    $self->_scientists->find($row->{scientist_name});
    $row->{scientist_id} = $scientist->id if $scientist;
    delete $row->{scientist_name};


    my @safe_columns = grep {
        $_ ne 'na_sequence_id' && defined $row->{$_}
    } keys %$row;

    my %revise_fields;
    @revise_fields{@safe_columns} = @$row{@safe_columns};

    my $new_rev = $sequence->create_revision({ %revise_fields });
    if (defined $new_rev) {
        log_info {[ "Created new revision %s", $new_rev->idrev ]};
        $self->track("Sequence revised");
    } else {
        log_info {[ "No changes required to %s", $sequence->idrev ]};
        $self->track("Sequence unchanged");
    }

}

1;
