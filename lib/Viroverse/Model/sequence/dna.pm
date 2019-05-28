use strict;
use warnings;
use 5.018;

package Viroverse::Model::sequence::dna;
use Moo;
BEGIN { extends 'Viroverse::Model::sequence' }

use Carp qw[carp];
use IPC::Open2;
use Scalar::Util qw< blessed >;
use Viroverse::Model::alignment;
use Viroverse::Model::na_sequence_alignment;
use Viroverse::Model::chromat_na_sequence;
use Viroverse::Model::protocol;
use ViroDB;
use Module::Runtime qw< require_module >;
use Viroverse::Logger qw< :log >;
use Mullins::AutopsyAbbreviations;
use Safe::Isa qw< $_call_if_object >;
use Try::Tiny;

# NOTICE: If you update these, please also update the _vhxb2 view in
# records in the genome_region table
# -silby, 2017-04-11
my %hxb2_region = (
    'gag'        => [790,2292],
    'gag-p17'=> [790,1186],
    'gag-p24'=> [1186,1879],
    'gag-p2' => [1879,1921],
    'gag-p7'    => [1921,2086],
    'gag-p1'    => [2086,2134],
    'gag-p6'    => [2134,2292],
    'pol'        => [2085,5096],
    'pol-prot'=>[2253,2550],
    'pol-rt'    => [2250,3870],
    'pol-rnase'=>[3870,4320],
    'pol-int'=> [4230,5096],
    'vif'        => [5041,5619],
    'vpr'        => [5559,5850],
    'tat1'    => [5831,6045],
    'rev1'    => [5970,6045],
    'env'        => [6225,8795],
    'env-gp120'=>[6225,7758],
    'env-gp41'=>[7558,8795],
    'tat2'    => [8379,8469],
    'rev2'    => [8379,8653],
    'nef'        => [8797,9417],
    'env-v3' => [7114, 7223]
);

__PACKAGE__->table('viroserve.na_sequence');
__PACKAGE__->columns(Primary => qw[ na_sequence_id na_sequence_revision ]);
__PACKAGE__->columns(Useful =>
   qw[
        scientist_id
          name
          sequence
          entered_date
          trimmed
          deleted
          na_type
    ]
);

__PACKAGE__->columns(TEMP => qw[_extraction]);


sub accessor_name_for {
    my ($self, $column) = @_;
    return $column eq 'sequence' ? 'seq' : $column;
}

__PACKAGE__->columns(Other =>
   qw[
          sample_id
          genbank_acc
    ]
);

__PACKAGE__->columns(TemplateForeignKeys => qw[
    pcr_product_id
    clone_id
]);

__PACKAGE__->sequence('viroserve.na_sequence_na_sequence_id_seq');

__PACKAGE__->has_a(scientist_id => 'Viroverse::Model::scientist');
__PACKAGE__->has_a(clone_id => 'Viroverse::Model::clone');
__PACKAGE__->has_a(pcr_product_id => 'Viroverse::Model::pcr');
__PACKAGE__->has_a(
    sample_id => 'ViroDB::Result::Sample',
    inflate => sub {
        return ViroDB->instance->resultset('Sample')->find($_[0]);
    },
    deflate => 'id',
);

with 'Viroverse::SampleTree::Node';

sub input_product {
    my $self = shift;
    return $self->pcr_product_id || $self->clone_id;
}

sub parent { $_[0]->input_product };
sub children { () };

sub revisions {
    my $self = shift;
    my @revisions = __PACKAGE__->search_where({ na_sequence_id => $self->na_sequence_id });
    return @revisions;
}

sub latest_revision {
    my $self = shift;
    my ($revision) = __PACKAGE__->search_where(
                                      {
                                          na_sequence_id       =>       $self->na_sequence_id,
                                      },
                                      {
                                          order_by      => ['na_sequence_revision desc'],
                                          limit         => 1,
                                          limit_dialect => 'Viroverse::CDBI',
                                      });
    return $revision;
}

sub parent_revision {
    my $self = shift;
    return if $self->na_sequence_revision == 1;
    my ($revision) = __PACKAGE__->search_where(
                                      {
                                          na_sequence_id       =>       $self->na_sequence_id,
                                          na_sequence_revision => {'<', $self->na_sequence_revision}
                                      },
                                      {
                                          order_by      => ['na_sequence_revision desc'],
                                          limit         => 1,
                                          limit_dialect => 'Viroverse::CDBI',
                                      });
    return $revision;
}

# These methods replace 'has_many' relationships because CDBI can't cope with
# has_many relationships from a model with a multi-column PK.
# -trs, 14 Nov 2013

# __PACKAGE__->has_many(alignments => ['Viroverse::Model::na_sequence_alignment' => 'alignment_id']);
sub alignments {
    my $self = shift;
    my @alignments = Viroverse::Model::na_sequence_alignment->search_where({ $self->pk_pairs });
    return map $_->alignment_id, @alignments;
}

sub chromats {
    my $self = shift;
    my @chromats = Viroverse::Model::chromat_na_sequence->search_where({ $self->pk_pairs });
    return map {$_->chromat_id} @chromats;
}

sub pk_pairs {
    map { $_ => $_[0]->$_ } $_[0]->primary_columns
}

# Part of this query also appears in Viroverse::Model::alignment as hxb2_by_seq
# and in the hxb2_stats view.
my $qual_essential_columns = __PACKAGE__->qualified_columns();
__PACKAGE__->set_sql('unaligned' => my $unaligned = qq[
    WITH max_rev AS (
        SELECT na_sequence_id, na_sequence_revision
          FROM viroserve.na_sequence_latest_revision
         WHERE na_sequence_id != 0
    )
    SELECT $qual_essential_columns FROM viroserve.na_sequence JOIN (
        SELECT * FROM max_rev EXCEPT
            SELECT na_sequence.na_sequence_id, na_sequence.na_sequence_revision
              FROM viroserve.na_sequence
              JOIN max_rev USING (na_sequence_id, na_sequence_revision)
              JOIN viroserve.na_sequence_alignment s ON (
                    na_sequence.na_sequence_id          = s.na_sequence_id
                AND na_sequence.na_sequence_revision    = s.na_sequence_revision
              )
              JOIN viroserve.na_sequence_alignment r ON (
                    s.alignment_id              = r.alignment_id
                AND s.alignment_revision        = r.alignment_revision
                AND s.alignment_taxa_revision   = r.alignment_taxa_revision
                AND r.is_reference IS TRUE
                AND r.na_sequence_id  = 0
                AND s.na_sequence_id != 0
              )
              JOIN viroserve.na_sequence_alignment_pairwise pairwise ON (
                    s.alignment_id              = pairwise.alignment_id
                AND s.alignment_revision        = pairwise.alignment_revision
                AND s.alignment_taxa_revision   = pairwise.alignment_taxa_revision
              )
    ) unaligned USING (na_sequence_id, na_sequence_revision)
    ORDER BY na_sequence_id DESC,
             na_sequence_revision DESC
]);
__PACKAGE__->set_sql('unaligned_limit' => "$unaligned LIMIT ?");

__PACKAGE__->set_sql('by_sample' => qq[
    SELECT __ESSENTIAL__
      FROM __TABLE__
      JOIN viroserve.na_sequence_latest_revision USING (na_sequence_id, na_sequence_revision)
     WHERE sample_id = ?
     ORDER BY na_sequence_id
]);

__PACKAGE__->set_sql('mark_deleted' => qq[
    UPDATE __TABLE__
       SET deleted = 't'
     WHERE na_sequence_id = ?
]);

sub retrieve_hxb2 {
    shift->retrieve(0);
}

# XXX TODO: For now, only return half of the PK because too much code expects it.
# -trs, 15 Nov 2013
sub give_id { $_[0]->na_sequence_id }
sub get_id  { $_[0]->na_sequence_id }

#convenience method to format sequence ID and revision
sub idrev {
    return $_[0]->na_sequence_id.'.'.$_[0]->na_sequence_revision;
}

=head2 shorthand

Returns C<dna_sequence> instead of the default C<dna>.

=cut

sub shorthand { "dna_sequence" }

=item retrieve
    overide CDBI retrieve to handle odd double PK
    if revision passed calls CDBI->retrive with both keys if only na_sequence_id passed (most common occurance)
    does a specail select to grab most current revision.

    @param $na_sequence_id Int required main part of primary key
    @param $revision Int optional   corresponds to na_sequence_revision half of table's PK
=cut
sub retrieve {
    my ($pkg, $na_sequence_id, $revision) = @_;

    # Support loading by id.rev
    ($na_sequence_id, $revision) = split /\./, $na_sequence_id, 2
        if $na_sequence_id =~ /^\d+\.\d+$/;

    if(defined ($revision)){
        return $pkg->SUPER::retrieve(na_sequence_id => $na_sequence_id, na_sequence_revision =>$revision);
    }

    # Use an iterator to avoid instantiating any object but the first.
    my $revisions = $pkg->search(na_sequence_id => $na_sequence_id, {order_by => 'na_sequence_revision DESC'});
    return $revisions->first;
}

sub retrieve_many {
    my $pkg = shift;
    my @ids = @_;

    return map { $pkg->retrieve($_) } @ids;
}

sub insert {
    die "Inserting sequences through the CDBI model is disabled!";
}

=head2 mark_deleted_by

Mark this sequence as deleted, though the record persists.  Takes a
L<Viroverse::Model::scientist> object as the first parameter (the I<who>) and a
textual note (the reason for the deletion) as the second (the I<why>).

B<All revisions> of this sequence are marked deleted.

Returns a tuple of C<(boolean, msg)> where C<boolean> indicates success or
failure and C<msg> is an error message, if any.

=cut

sub mark_deleted_by {
    my ($self, $who, $why) = @_;
    return (0, "Permission denied")  unless $self->scientist_can_delete($who);
    return (0, "No reason provided") unless defined $why and $why =~ /\S/;

    my $dbh = $self->db_Main;
    try {
        $dbh->begin_work;

        my $sth = $self->sql_mark_deleted;
        $sth->execute($self->na_sequence_id);
        die "No rows affected by UPDATE"
            unless $sth->rows >= 1;

        $self->add_note({
            note         => "[Delete] $why",
            scientist_id => $who->id,
        });
    } catch {
        $dbh->rollback;
        log_error {[ "Couldn't mark sequence %d deleted: %s", $self->na_sequence_id, $_ ]};
        return (0, "Couldn't mark deleted: $_");
    };
    $dbh->commit;
    return 1;
}

=head2 scientist_can_delete

Given a L<Viroverse::Model::scientist> object, returns a boolean indicating if
the scientist may mark this sequence deleted or not.

=cut

sub scientist_can_delete {
    my ($self, $sci) = @_;
    return 1 if $sci->role eq "admin";
    return 1 if $sci->role eq "supervisor";
    return 0;
}


=head2 queue_reference_align

Creates a job to needle align this sequence with HXB2.  Returns early if
L<Beanstalk::Client> isn't available, as this method is called automatically by
L</after_create>.

Returns a tuple of (L<Beanstalk::Job> object, message).  On failure, the job
will be undef and the message will contain L<Beanstalk::Client/error>.

=cut

sub queue_reference_align {
    my $self = shift;
    my %opts = @_;

    unless (require_module('Beanstalk::Client')) {
        log_warn { "Skipping queueing of reference alignment job because Beanstalk::Client isn't available" };
        return (undef, 'Beanstalk::Client not available');
    }

    state $queue = do {
        my $q = Beanstalk::Client->new;
        $q->use('align/needle');
        $q;
    };
    my $job = $queue->put(
        { ttr => 120, %opts },
        {
            reference_id => __PACKAGE__->retrieve_hxb2->idrev,
            query_id     => $self->idrev,
        }
    );
    return $job ? ($job, 'OK') : (undef, $queue->error);
}

=item hxb2_coverage
list hxb2 start/end for aligned sequence
=cut

#TODO: cache this info
sub hxb2_coverage {
    my $self = shift;
    carp "not a package method" unless ref $self;

    my $hxb2_aln = $self->hxb2_aln;
    return unless $hxb2_aln;

    my @regions = $hxb2_aln->pairwise_pieces;
    return ($regions[0]->reference_start,$regions[-1]->reference_end);
}

sub parse_name_vv {
    my ($pkg,$name) = @_;

    return unless $name;

    my ($seq_id,$seq_rev) = $name =~ m/^(\d+)\.(\d+)/;

    return $seq_id,$seq_rev;

}

sub hxb2_cds {
    my $self = shift;
    my @cds  = sort { $hxb2_region{$a}->[0] <=> $hxb2_region{$b}->[0] }
               grep { not /-/ }
               keys %hxb2_region;

    my (@covers, @overlaps);
    my @coords = $self->hxb2_coverage
        or return;

    for my $cds_name (@cds) {
        my $cds_coords = $hxb2_region{$cds_name};
        push @covers,   $cds_name if $coords[0] <= $cds_coords->[0] and $coords[1] >= $cds_coords->[1];
        push @overlaps, $cds_name if $coords[0] <= $cds_coords->[1] and $coords[1] >= $cds_coords->[0];
    }

    return {
        covers   => \@covers,
        overlaps => \@overlaps,
    };
}

sub hxb2_aln {
    my $self = shift;

    my @alignments = Viroverse::Model::alignment->search_hxb2_by_seq($self->na_sequence_id,$self->na_sequence_revision);
    if ($#alignments >= 0) {
        return $alignments[0];
    }
}

sub as_search_data {
    my $self = shift;

    return ViroDB->instance->resultset("SequenceSearch")->search({
        na_sequence_id => $self->na_sequence_id,
        na_sequence_revision => $self->na_sequence_revision
    })->single;
}

sub alignments_with {
    my $self = shift;

    return Viroverse::Model::alignment->search_by_seq($self->na_sequence_id,$self->na_sequence_revision);
}

sub tissue_molecule_abbreviation {
    my $self = shift;
    # XXX TODO: Extend this to more than Autopsy at some point…
    # -trs, 31 Dec 2015
    return Mullins::AutopsyAbbreviations::tissue_molecule_abbreviation(
        $self->sample_id->tissue_type->name,
        $self->na_type
    );
}

sub amplicon {
    my $self = shift;
    # XXX TODO: Extend this to more than Autopsy at some point…
    # -trs, 31 Dec 2015
    return Mullins::AutopsyAbbreviations::amplicon($self);
}

sub to_hash {
    my $self = shift;
    my @coverage = $self->hxb2_coverage;
    my $sample   = $self->sample_id;

    my $date = $sample ? $sample->date : undef;
       $date = $date->strftime('%Y-%m-%d')
            if $date;

    return {
        id           => $self->na_sequence_id,
        revision     => $self->na_sequence_revision,
        idrev        => $self->idrev,
        name         => $self->name,
        patient      => ($sample ? scalar $sample->patient->$_call_if_object("name") : undef),
        visit_date   => $date,
        tissue_type  => ($sample ? scalar $sample->tissue_type->$_call_if_object("name") : undef),
        na_type      => $self->na_type,
        start        => $coverage[0],
        end          => $coverage[1],
        deleted      => ($self->deleted ? \1 : \0),
    };
}

1;
