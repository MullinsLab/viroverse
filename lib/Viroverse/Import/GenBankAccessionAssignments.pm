use strict;
use warnings;
use utf8;
use 5.018;

package Viroverse::Import::GenBankAccessionAssignments;
use Moo;
use Types::Common::String qw< NonEmptySimpleStr >;
use Types::Standard -types;
use ViroDB;
use Viroverse::Logger qw< :log :dlog >;
use namespace::clean;

with 'Viroverse::Import';

=head1 DESCRIPTION

=encoding UTF-8

This importer is for assigning GenBank accessions to existing Viroverse
sequences, which is useful for keeping track of what has been submitted to
GenBank.

=cut

__PACKAGE__->metadata->set_label("GenBank Accession Assignments");
__PACKAGE__->metadata->set_primary_noun("sequence");

has '+key_map' => (
    isa => Dict[
        idrev             => NonEmptySimpleStr,
        genbank_accession => NonEmptySimpleStr,
    ],
);

sub suggested_column_for_key_pattern {
    my ($package, $key) = @_;
    return {
        idrev             => qr/idrev|viroverse|na_sequence_id/i,
        genbank_accession => qr/genbank_accession|genbank|accession/i,
    }->{$key};
}

sub process_row {
    my ($self, $row) = @_;
    state $db = ViroDB->instance;

=pod

Sequences are looked up by the full Viroverse accession (C<id.rev>).  Although
it is not recommended, you may update the latest revision of a sequence by
omitting the revision part of the accession.

=cut

    my $sequence = $db->resultset("NucleicAcidSequence")
        ->find_by_idrev( $row->{idrev} )
            or die "Sequence $row->{idrev} doesn't exist";

    die "Sequence $row->{idrev} is marked deleted.  ",
        "Please undelete the sequence or otherwise handle this exceptional case."
            if $sequence->deleted;

=pod

Warnings will be generated in the import log if the Viroverse accession isn’t
the latest for a sequence, indicating that the sequence may have changed in
Viroverse since being submitted to GenBank.

=cut

    my $latest = $db->resultset("NucleicAcidSequenceLatestRevision")
        ->find({ na_sequence_id => $sequence->na_sequence_id });

    unless ($sequence->na_sequence_revision == $latest->na_sequence_revision) {
        log_warn {[ "Sequence %s is an outdated revision; the latest is %s", $sequence->idrev, $latest->idrev ]};
        $self->track("Outdated revision");
    }

=pod

The import will throw an error and fail if the GenBank accession for a
sequence is already set to a I<different> value than in the imported data file.

=cut

    my $old = $sequence->genbank_acc;
    my $new = $row->{genbank_accession}
        or die "No GenBank accession provided for sequence ", $sequence->idrev;

    if ($old) {
        if ($old eq $new) {
            log_debug {[ "No changes required for sequence %s", $sequence->idrev ]};
            $self->track("GenBank accession unchanged");
            return;
        } else {
            die sprintf "Sequence %s has an existing GenBank accession, %s, which is different than %s",
                $sequence->idrev, $old, $new;
        }
    }

    log_debug {[ "Updating GenBank accession for sequence %s", $sequence->idrev ]};
    $self->track("GenBank accession assigned");

    $sequence->update({ genbank_acc => $new });
}

1;
