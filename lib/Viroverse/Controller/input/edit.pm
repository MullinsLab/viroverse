package Viroverse::Controller::input::edit;
use base 'Viroverse::Controller';

use strict;
use warnings;
use Carp;

=head1 NAME

Viroverse::Controller::input::edit - holds Catalyst actions to edit materials entered via input

=head1 METHODS
=cut

sub section {
    return 'input';
}

sub subsection {
    return 'sequence';
}

 
=item pcr_nickname

    accepts id of pcr product and new nickname as (URL) arguments, in that order

=cut

sub pcr_nickname : Path('pcr/nickname') {
    my ($self, $context) = @_;

    my ($pcr_id,$new_nick) = @{$context->req->arguments};

    if (! $pcr_id >0 && $new_nick)  {
        $context->respose->body('NOK');
        return;
    }

    Viroverse::Model::pcr->db_Main->begin_work;

    my $p = Viroverse::Model::pcr->retrieve($pcr_id);

    if (!$p) {
        $context->respose->body('NOK');
        return;
    }

    $p->name($new_nick);

    $context->response->body('OK');

    Viroverse::Model::pcr->db_Main->commit;
}

sub extraction_conc : Path('extraction/concentration') {
    my ($self, $context) = @_;

    my ($e_id,$new_conc) = @{$context->req->arguments};

    if (! $e_id >0 && $new_conc) {
        $context->respose->body('NOK');
        return;
    }

    Viroverse::Model::pcr->db_Main->begin_work;

    my $e = Viroverse::Model::extraction->retrieve($e_id);

    if (!$e) {
        $context->respose->body('NOK');
        return;
    }

    $e->concentration($new_conc);
    $e->concentration_unit_id( Viroverse::Model::unit->search_single('ng/ul') );

    $context->response->body('OK');

    Viroverse::Model::pcr->db_Main->commit;
}

1;
