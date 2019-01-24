package Viroverse::Controller::summary;

use strict;
use warnings;
use base 'Viroverse::Controller';
use Viroverse::patient;
use Path::Tiny;
use Catalyst::ResponseHelpers;
use Sort::Naturally qw< ncmp >;

=head1 NAME

Viroverse::Controller::summary - Output summaries of VV objects

=head1 SYNOPSIS

See L<Viroverse>

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub section { 'browse' }

sub index : Private {
    my ($self, $context) = @_;

    $context->stash->{template} = 'browse_home.tt';
}

sub copy_number : Local {
    my ($self, $c, $copy_number_id) = @_;
    my $copy_number = $c->model("ViroDB::CopyNumber")->find($copy_number_id)
        or return NotFound($c, "Unable to find copy number #$copy_number_id");
    my @positives = $copy_number->gel_lanes->search(
        { pcr_product_id => { -not => undef }, pos_result => 1 }
    );
    my %gels = ();
    for my $lane (@positives) {
        push @{$gels{$lane->gel_id}}, {
            label    => $lane->formatted_label,
            nickname => $lane->pcr_product->name
        };
    }
    for my $v (values %gels) {
        @$v = sort { ncmp($a->{label},  $b->{label}) } @$v;
    }
    my $sample = $copy_number->input_sample;

    $c->stash(
        copy_number => $copy_number,
        template    => 'summary/copy-number.tt',
        gels        => \%gels,
        sample      => $sample
    );

    $c->detach('Viroverse::View::NG');
}

sub gel : Local {
    my ($self, $c, $gel_id) = @_;
    my $gel = Viroverse::Model::gel->retrieve($gel_id)
        or return NotFound($c, "Unable to find gel #$gel_id");

    $c->stash(
        gel         => $gel,
        template    => 'sum-gel.tt',
    );
}

sub gel_img : Local {
    my ($self, $context) = @_;
    my $gel_id = shift @{$context->request->arguments};

    my $gel_obj = Viroverse::Model::gel->retrieve($gel_id);

    $context->log->error('gel summary requires image') unless $gel_id;
    $context->stash->{img_content_type} = $gel_obj->mime_type;
    $context->stash->{img_contents} = $gel_obj->image;
    $context->forward('Viroverse::View::image');

}

sub mini : Local {
    my ($self,$context) = @_;

    return unless my ($type,$id) = @{$context->request->arguments};

    if ( $context->stash->{object} = $context->forward('Viroverse::Controller::need','find_a',[$type,$id]) ) {
        $context->stash->{template} = "${type}_mini.tt";
    }
}

=head1 AUTHORS

Brandon Maust

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
