package Viroverse::Controller::partials;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=encoding utf8

=head1 NAME

Viroverse::Controller::partials - Handles serving view partials to JS

=head1 METHODS

=head2 product_patient_filter

=cut

sub product_patient_filter :Local {
    my ($self, $c) = @_;
    $c->stash->{template} = 'partials/product_patient_filter.tt';
    $c->stash->{cohorts}  = $c->model("ViroDB::Cohort")->list_all;
}

=head2 product_tissue_filter

=cut

sub product_tissue_filter :Local {
    my ($self, $c) = @_;
    $c->stash->{template} = 'partials/product_tissue_filter.tt';
    $c->stash->{tissues}  = Viroverse::sample->list_tissue_types($c->stash->{session});
}

=head1 AUTHOR

Thomas Sibley

=head1 COPYRIGHT

2013 Mullins Lab, University of Washington

=cut

__PACKAGE__->meta->make_immutable;

1;
