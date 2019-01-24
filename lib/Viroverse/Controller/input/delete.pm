package Viroverse::Controller::input::delete;
use base 'Viroverse::Controller';

use strict;
use warnings;
use Try::Tiny;

use Viroverse::Controller::need;

=head1 NAME

Viroverse::Controller::input::delete - Legacy controller for deleting PCR
products

=head1 METHODS
=cut

sub section : Private {
    return 'input';
}

sub subsection : Private {
    return 'sequence';
}

sub default : Path {
    my ($self, $context) = @_;

    my ($type,@ids) = @{$context->req->arguments};

    $context->log->debug("hit delete with $type @ids");
    if (! @ids || $type ne "pcr")  {
        $context->response->body('NOK');
        return;
    }

    my $pcrs = $context->model("ViroDB::PolymeraseChainReactionProduct");

    my $txn = $pcrs->result_source->schema->txn_scope_guard;

    foreach my $id (sort {$b <=> $a} @ids) {

        $context->log->debug("deleting $type $id");

        my $pcr = $pcrs->find($id);

        my $allowed =
            ($context->stash->{scientist}->is_admin
                || $context->stash->{scientist}->scientist_id == $pcr->scientist_id)
            && ! $pcr->pcr_pool_id
            && ! $pcr->gel_lanes->count
        ;
        if ($allowed) {
            try {
                my $template = $pcr->pcr_template;
                $pcr->primer_assignments->delete;
                $pcr->delete;
                $template->delete;
            } catch {
                $context->log->debug("delete failed for $type $id");
                $context->response->body('NOK');
                return 0;
            } or return;
        } else {
            $context->log->debug("delete not permitted for $type $id");
            $context->response->body('NOK');
            return;
        }
    }

    try {
        $txn->commit;
        $context->forward('Viroverse::Controller::sidebar','remove',[$type,@ids]); #this may not "succeed" if products were not in sidebar
        $context->response->body('OK');
    } catch {
        $context->log->debug("delete unsuccessful");
        $context->response->body('NOK');
    };
}

1;
