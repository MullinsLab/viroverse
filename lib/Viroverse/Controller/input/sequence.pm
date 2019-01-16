use strict;
use warnings;
use utf8;
use 5.018;

package Viroverse::Controller::input::sequence;
use Moose;
use Fasta;
use Try::Tiny;
use Catalyst::ResponseHelpers;
use List::Util 1.45 qw< pairs pairgrep pairmap uniq >;
use List::UtilsBy qw< sort_by partition_by >;
use Viroverse::Logger qw< :log :dlog >;
use namespace::autoclean;

BEGIN { extends 'Viroverse::Controller' }

sub section    { 'input'    }
sub subsection { 'sequence' }

sub base : Chained('/') PathPart('input/sequence') CaptureArgs(0) { }

sub index : GET Chained('base') PathPart('') Args(0) {
    my ($self, $c) = @_;

    $c->session->{sidebar}{pcr_more} =
        $c->model('pcr')->organize_ids_primers( $c->session->{sidebar}{pcr_more} );

    $c->controller('sidebar')->sidebar_to_stash($c);

    $c->stash(
        find_a   => [{ name => 'pos_pcr', label => 'PCR product' }],
        template => 'sequencing_start.tt',
    );
    $c->detach( $c->view('TT') );
}

sub by_products : GET Chained('base') PathPart('by_products') Args(0) {
    my ($self, $c) = @_;

    $c->controller('sidebar')->sidebar_to_stash($c);
    $c->stash(
        template       => 'input/sequence/by_products.tt',
        sequence_types => [
            $c->model("ViroDB::SequenceType")
                ->order_by("name")
        ],
    );
    $c->detach( $c->view('NG') );
}

sub add : POST Chained('base') PathPart('add') Args(0) {
    my ($self, $context) = @_;
    my $chromat_type = $context->model("ViroDB::ChromatType");

    # Organize uploaded files for looping over PCR IDs
    # {
    #   $pcr_id =>
    #     { sequence => [$file_ref, ...], chromats => [$file_ref, ...], sequence_type => ... },
    #   $other_pcr_id =>
    #     ...
    # }
    my @pcrs      = $context->req->param('pcr_ids');
    my $materials = {
        map {
            $_ => {
                sequence_type => $context->req->params->{"prod-$_-sequence-type"},
                na_type       => $context->req->params->{"prod-$_-na-type"},
                skip_chromats => $context->req->params->{"prod-$_-skip_chromats"},

                partition_by {
                    # If we can identify a chromat type from the data, then
                    # it's a chromat.  Otherwise, trust it's a FASTA.
                    $chromat_type->find_from_data( $_->slurp )
                        ? "chromats"
                        : "sequence"
                } $context->req->upload("prod-$_-files")
            }
        } @pcrs
    };

    my @seqs;

    my $needs_confirm_primers = 0;

    try {
        my $txn = $context->model("ViroDB")->schema->txn_scope_guard;

        # Loop over the list of PCR ids rather than the keys of $materials so
        # that we process sequences in the same order as they appeared on the
        # upload page.  This, in turn, means we report the created sequences in
        # the same order too, which is nice UX.

        for my $pcr_id (@pcrs) {
            my $pcr = $context->model('ViroDB::PolymeraseChainReactionProduct')->find($pcr_id)
                or die "Unable to find PCR «$pcr_id»";

            die "You must provide a consensus sequence for ", $pcr->name // $pcr_id
                unless @{ $materials->{$pcr_id}{sequence} // [] };

            die "More than one consensus sequence uploaded for ", $pcr->name // $pcr_id
                unless @{ $materials->{$pcr_id}{sequence} } == 1;

            if (@{ $materials->{$pcr_id}{chromats} // [] }) {
                $needs_confirm_primers = 1;
            } elsif (!$materials->{$pcr_id}->{skip_chromats}) {
                die "You must provide chromats for ", $pcr->name // $pcr_id
            }

            my $fa_string = $materials->{$pcr_id}{sequence}[0]->slurp;
            my %fa = %{Fasta::string2hash(\$fa_string)};

            die "Multiple sequences inside uploaded FASTA file for ", $pcr->name // $pcr_id
                if scalar keys %fa > 1;

            my $name = (keys %fa)[0];

            # In lieu of porting the MolecularProduct stuff into ViroDB, just
            # get the sample of the PCR from CDBI.
            my $cdbi_pcr = $context->model('pcr')->retrieve($pcr_id);
            my $sample = $context->model("ViroDB::Sample")->find($cdbi_pcr->sample_id->give_id);
            my $type_id = $materials->{$pcr_id}->{sequence_type};
            my $type;
            if (defined $type_id) {
                $type = $context->model("ViroDB::SequenceType")->find($type_id)
                    or die "Unknown sequence type";
            }

            my $seq = $pcr->na_sequences->create({
                name          => $name,
                sequence      => $fa{$name},
                na_type       => $materials->{$pcr_id}->{na_type},
                sample        => $sample,
                scientist_id  => $context->stash->{scientist}->scientist_id,
                type          => $type,
            });
            $seq->discard_changes;
            for my $chromat (@{$materials->{$pcr_id}->{chromats}}) {
                # Take heed!  The add_to_chromats method does a find_or_create
                # of chromats instead of just a create.¹  It always adds the
                # link table row, which means different sequences may end up
                # with the same chromats if the same files are uploaded.  This
                # is… actually sorta ok I think—kinda like a poor man's CAS—but
                # it definitely wasn't originally expected.
                #
                # One reason to stop doing this is that matching on a binary
                # blob probably slows down this operation, and we often do the
                # operation dozens of times per upload batch.  We should also
                # really start storing the chromat data outside of the
                # database; it belongs in the filesystem, using a real CAS.
                #
                # ¹ https://rt.cpan.org/Ticket/Display.html?id=124501
                #
                $seq->add_to_chromats({
                    data         => $chromat->slurp,
                    name         => $chromat->filename,
                    scientist_id => $context->stash->{scientist}->scientist_id,
                });
            }
            push @seqs, $seq;
        }
        $txn->commit;

        # The enqueuing of reference alignment jobs needs to be refactored out
        # of the CDBI model but the queuing of jobs shouldn't ultimately live in
        # a model, I think, so I'm not moving it to the ViroDB model.
        for my $seq (@seqs) {
            my $cdbi = $context->model('sequence::dna')->retrieve($seq->idrev);
            $cdbi->queue_reference_align( delay => 2 );
        }
    } catch {
        my $error = $_ =~ s/ at \S+ line \d+.*//rs;

        return Redirect($context, $self->action_for('by_products'), {
            mid => $context->set_error_msg("Error uploading sequences: $error")
        });
    };
    $context->session->{sidebar}->{dna_sequence} = [map {$_->na_sequence_id} @seqs];
    return Redirect($context, $self->action_for($needs_confirm_primers ? 'confirm_primers' : 'review'));
}

sub confirm_primers : GET Chained('base') PathPart('confirm_primers') Args(0) {
    my ($self, $c) = @_;

    my @seqs = $c->model("ViroDB::NucleicAcidSequence")->search_by_idrevs(
        @{ $c->session->{sidebar}->{dna_sequence} }
    );

    return Redirect($c, $self->action_for('index'))
        unless @seqs;

    $c->stash(
        sequences => [ sort_by { fc($_->name) } @seqs ],

        # Instead of the standard primer sort by orientation, then name,
        # we just sort by name to allow easier typeahead lookup
        all_primers => [ sort_by { fc($_->name) } Viroverse::Model::primer->retrieve_all ],

        template => 'input/sequence/confirm-primers.tt',
    );
    $c->detach( $c->view('NG') );
}

sub update_primers : POST Chained('base') PathPart('update_primers') Args(0) {
    my ($self, $c) = @_;

    # Map to chromat id => primer id pairs
    my %chromat_primers =
        pairmap { $a =~ /chromat-(\d+)-primer/ ? ($1, $b) : () }
               %{ $c->req->params };

    Dlog_debug { "Submitted chromat primer map: $_" } \%chromat_primers;


    # Check for chromats with discordant primer ids, which can happen if
    # multiple sequences are uploaded for the same set of chromats and the
    # uploader specifies different primers.
    my %discordant =
       pairgrep { uniq(@$b) > 1 }
       pairgrep { ref $b eq 'ARRAY' }
                %chromat_primers;

    Dlog_fatal { "Discordant primers: $_" } \%discordant
        if %discordant;


    # Resolve multiple primer ids in param map for easier processing.
    %chromat_primers =
        pairmap { ref $b eq 'ARRAY' ? ($a => $b->[0]) : ($a => $b) }
                %chromat_primers;

    Dlog_debug { "Final chromat primer map: $_" } \%chromat_primers;


    # Update each chromat with a primer.
    my $txn = Viroverse::CDBI->txn_scope_guard;

    for (pairs %chromat_primers) {
        my ($chromat_id, $primer_id) = @$_;
        my $chromat = Viroverse::Model::chromat->retrieve($chromat_id);
        $chromat->primer_id($primer_id);
    }
    $txn->commit;

    return Redirect($c, $self->action_for("review"));
}

sub review : GET Chained('base') PathPart('review') Args(0) {
    my ($self, $c) = @_;

    # Remove PCR products from sidebar now that we've sequenced them and make
    # sure sidebar sequences are available for the sidebar template.
    $c->controller('sidebar')->clear($c, "pcr", "pcr_more");
    $c->controller('sidebar')->sidebar_to_stash($c);

    # Our own template wants ViroDB objects
    my @seqs = $c->model("ViroDB::NucleicAcidSequence")->search_by_idrevs(
        @{$c->session->{sidebar}->{dna_sequence}}
    );

    $c->stash(
        sequences => [ sort_by { fc($_->name) } @seqs ],
        template  => 'input/sequence/review.tt',
    );
    $c->detach( $c->view('NG') );
}

1;
