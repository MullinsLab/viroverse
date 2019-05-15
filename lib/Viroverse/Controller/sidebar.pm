package Viroverse::Controller::sidebar;
use base 'Viroverse::Controller';

use strict;
use warnings;

use Viroverse::Model::extraction;
use Viroverse::patient;
use Viroverse::Model::rt;
use Viroverse::sample;
use Viroverse::Model::scientist;
use Viroverse::Model::gel;
use Viroverse::Model::sequence::dna;
use Viroverse::Logger qw< :log >;
use Fasta;
use List::Util qw[first];
use List::MoreUtils qw[firstidx uniq];
use Data::Dump;
use Carp;
use Viroverse::Controller::need;

=head1 NAME

Viroverse::Controller::input - Holds Catalyst actions under /input to create data in Viroverse

=head1 SYNOPSIS

See L<Viroverse>

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub sidebar_to_stash : Local {
    my ($self, $context) = @_;
    foreach my $type (keys %{$context->session->{sidebar}}) {
        if (ref $context->session->{sidebar}->{$type} && $Viroverse::Controller::need::instantiate_for{$type}) {
            foreach my $id (@{$context->session->{sidebar}->{$type}}) {
                my $inst = $Viroverse::Controller::need::instantiate_for{$type}($context,$id);
                if ($inst) {
                    push @{$context->stash->{$type}}, $inst;
                } else {
                    @{$context->session->{sidebar}->{$type}} =
                        grep { $_ != $id } @{$context->session->{sidebar}->{$type}};
                    log_error { "Couldn't retrieve sidebar item: $type ID $id" };
                }
            }
        }
    }
}

sub add : Local {
    my ($self, $context, $type, @ids) = @_;
    my %touched;

    foreach my $id (@ids) {
        if (my $dbl_check = $Viroverse::Controller::need::instantiate_for{$type}($context,$id) ) {
            my $touched_type = $type;
            if ($type eq 'found_aliquots') {
                # don't push deleted vials onto sidebar
                push @{$context->session->{sidebar}->{$type}}, $id
                    unless $dbl_check->is_deleted;
            }
            elsif ($type =~ /^sample/) { # special case to resolve sample.rna, sample.dna to
                                         # sample to avoid adding the shorthand interface
                                         # to ViroDB::Result::Sample
                $touched_type = "sample";
                push @{$context->session->{sidebar}->{sample}}, $id;
            }
            elsif ($dbl_check->can('shorthand') && $dbl_check->shorthand) {
                $touched_type = $dbl_check->shorthand;
                push @{$context->session->{sidebar}->{$dbl_check->shorthand}}, $id;
            }
            else {
                push @{$context->session->{sidebar}->{$type}}, $id;
            }
            $touched{$touched_type}++;
        }
    }
    $context->session->{sidebar}{$_} = [uniq @{$context->session->{sidebar}{$_}}]
        for keys %touched;
}

sub extraction : Local {
    my ($self, $context) = @_;

    $context->forward('sidebar_to_stash');
    $context->forward('extraction_prepare');

    $context->stash->{template} = 'extraction-sidebar.tt';
}

sub extraction_prepare : Local {
    my ($self, $context) = @_;
    my $dna = 0;
    my $rna = 0;
    foreach my $obj (@{$context->stash->{extraction}}) {
        $dna = 1 if $obj->extract_type_id->name eq 'DNA';
        $rna = 1 if $obj->extract_type_id->name eq 'RNA';
    }

    $context->stash->{extraction_has_dna} = $dna;
    $context->stash->{extraction_has_rna} = $rna;
}

=item reload
       Reloads sidebar when needed (should replace most of the one off functions below)
       @arg $template string name of template to load data in
=cut
sub reload : Local {
   my ($self, $c) = @_;

   my $template = $c->req->args->[0];
   $c->forward('sidebar_to_stash');
   $c->stash->{template} = $template;
}

sub rt : Local {
    my ($self, $context) = @_;

    if (ref $context->session->{sidebar}->{rt}) {
        foreach my $rt_id (@{$context->session->{sidebar}->{rt}}) {
            push @{$context->stash->{rt}}, Viroverse::Model::rt->retrieve($rt_id);
        }
    }

    $context->stash->{template} = 'rt-sidebar.tt';
}

sub bisulfite_converted_dna : Local {
    my ($self, $context) = @_;

    if (ref $context->session->{sidebar}->{bisulfite_converted_dna}) {
        foreach my $bisulfite_converted_dna_id (@{$context->session->{sidebar}->{bisulfite_converted_dna}}) {
            push @{$context->stash->{bisulfite_converted_dna}}, Viroverse::Model::bisulfite_converted_dna->retrieve($bisulfite_converted_dna_id);
        }
    }

    $context->stash->{template} = 'bisulfite-converted-dna-sidebar.tt';
}

sub pcr : Local {
    my ($self, $context) = @_;
    $context->forward('gel_sidebar_to_stash');
    $context->forward('sidebar_to_stash');

    $context->stash->{template} = 'pcr-sidebar.tt';
}

sub gel_sidebar_to_stash : Local {
    my ($self, $context) = @_;

    ## gel to stash
    while (my ($type,$val_ref) = each %{$context->session->{sidebar}->{to_gel}}) {

        if (ref $val_ref && $Viroverse::Controller::need::instantiate_for{$type}) {
            foreach my $id (@{$val_ref}) {
                push @{$context->stash->{to_gel}->{$type}}, $Viroverse::Controller::need::instantiate_for{$type}($context,$id);

            }
        }
    }
}

sub gel : Local {
    my ($self, $context) = @_;

    $context->forward('gel_sidebar_to_stash');
    $context->forward('sidebar_to_stash');

    $context->stash->{template} = 'gel-sidebar.tt';
}

sub dna_sequence : Local {
    my ($self, $context) = @_;
    $context->forward('sidebar_to_stash');
    $context->stash->{template} = 'sidebar/dna_sequence.tt';
    $context->detach('Viroverse::View::NG');
}

sub aliquot : Local {
    my ($self, $context) = @_;
    $context->forward('sidebar_to_stash');
    $context->stash->{template} = 'freezer-sidebar.tt';
    return;
}

sub found_aliquots : Local {
    my ($self, $context) = @_;
    $context->forward('sidebar_to_stash');
    $context->stash->{template} = 'freezer-sidebar.tt';
    return;
}

sub gel_remove_first_round_pcr : Local {
    my ($self, $context) = @_;
    return $self->gel_remove_rounds_up_to($context, 1);
}

sub gel_remove_first_and_second_round_pcr : Local {
    my ($self, $context) = @_;
    return $self->gel_remove_rounds_up_to($context, 2);
}

sub gel_remove_rounds_up_to : Private {
    my ($self, $context, $round) = @_;
    $context->forward('gel_sidebar_to_stash');

    my @keep;
    foreach my $pcr (@{$context->stash->{to_gel}->{pcr}}) {
        push @keep, $pcr->give_id if $pcr->round > $round;
    }

    $context->session->{sidebar}->{to_gel}->{pcr} = \@keep;
    $context->stash->{to_gel} = {};

    $context->forward('gel');
}


sub gel_organize_pcr_by_primer : Local {
    my ($self,$context) = @_;

    my $pcr    = $context->session->{sidebar}->{to_gel}->{pcr};
    my $sorted = Viroverse::Model::pcr->organize_ids_primers($pcr);

    if (join("\0", @$pcr) eq join("\0", @$sorted)) {
        @$pcr = reverse @$sorted;
    } else {
        @$pcr = @$sorted;
    }
    $context->forward('gel');
}

# The intent of pcr_more is to hold PCRs to which "more" can be done, which are
# generally (though perhaps not necessarily always) ones that are positive.
# I.e., it's the pcr_more-sidebar (previously pos_pcr-sidebar) that displays
# those things for operating on, and hence where the button to carry positive
# products into Sequencing from a completed Gel Label step appears.
sub pcr_more : Local {
    my ($self, $context) = @_;
    my $pcr = $context->session->{sidebar}->{pcr} // [];
    $context->session->{sidebar}->{pcr_more} = $pcr;
    $context->forward('sidebar_to_stash');

    $context->stash->{template} = 'pcr_more-sidebar.tt';
}

sub pos_pcr : Local {
    my ($self, $context) = @_;
    $context->forward('pcr_more');
}

sub pcr_pool : Local {
    my ($self, $context) = @_;
    $context->forward('sidebar_to_stash');

    $context->stash->{template} = 'pcr_pool-sidebar.tt';
}

sub gel_remove : Local {
    my ($self, $context) = @_;

    my ($type,$loc) = @{$context->request->arguments};

    if (exists $context->session->{sidebar}->{to_gel}->{$type}) {
        if ($loc != -1) {
            splice(@{$context->session->{sidebar}->{to_gel}->{$type}},$loc,1);
            $context->response->body('OK');
        } else {
        $context->response->body('NOK');
        }
    } else {
    $context->response->body('NOK');
    }

}

sub remove : Local {
    my ($self, $context) = @_;

    my ($type,$id) = @{$context->request->arguments};
    my $loc;
    if (exists $context->session->{sidebar}->{$type}) {
        $loc =firstidx { $_ == $id } @{$context->session->{sidebar}->{$type}};
        if ($loc != -1) {
            splice(@{$context->session->{sidebar}->{$type}},$loc,1);
            $context->response->body('OK');
        } else {
        $context->response->body('NOK');
        }
    } else {
        $context->response->body('NOK');
    }
    return;
}

sub remove_type : Local {
    my ($self, $context) = @_;
    my $type = shift @{$context->request->arguments};
    if (! exists $context->session->{sidebar}->{$type}) {
        $context->response->body('OK');
    } else {
        delete $context->session->{sidebar}->{$type};
        $context->response->body('OK');
    }

    return;
}

sub dump : Local {
    my ($self, $context) = @_;
    $context->response->body(Data::Dump::dump( $context->session->{sidebar} ));
}

sub clear : Local {
    my ($self, $c, @types) = @_;
    delete $c->session->{sidebar}{$_} for @types;
}

sub gel_clear : Local {
    my ($self, $context) = @_;
    delete $context->session->{sidebar}->{to_gel};
    delete $context->session->{sidebar}->{gel};

    $context->forward('gel');
}

sub pcr_clear : Local {
    my ($self,$context) = @_;
    delete $context->session->{sidebar}->{to_gel}->{pcr};

    $context->forward('pcr');
}

sub pcr_more_clear : Local {
    my ($self,$context) = @_;
    delete $context->session->{sidebar}->{pcr};
    delete $context->session->{sidebar}->{pcr_more};

    $context->forward('pos_pcr');
}


=head1 AUTHORS

Wenjie Deng and Brandon Maust

=cut

1;
