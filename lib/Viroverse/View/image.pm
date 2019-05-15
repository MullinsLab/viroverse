package Viroverse::View::image;

use strict;
use warnings;
use GD;
use base 'Catalyst::View';

=head1 NAME

Viroverse::View::image - Catalyst View to render image from stash directly to browser

=head1 SYNOPSIS


=head1 DESCRIPTION

=cut

sub process {
    my ($self, $context) = @_;

    $context->response->content_type($context->stash->{img_content_type});
    $context->response->header('Content-Disposition' => 'inline;');
    $context->response->body($context->stash->{img_contents});

    return 1;
}


=head1 AUTHOR

Brandon Maust

=cut

1;
