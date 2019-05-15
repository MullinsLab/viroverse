package Viroverse::Controller::need;
use base 'Viroverse::Controller';

use strict;
use warnings;

use Viroverse::Model::clone;
use Viroverse::Model::extraction;
use Viroverse::Model::gel_lane::special;
use Viroverse::Model::bisulfite_converted_dna;
use Viroverse::Model::rt;
use Viroverse::sample;
use Viroverse::Model::sequence::dna;

=head1 NAME

Viroverse::Controller::need - Holds private actions to retrieve an object or redirect to create one

=cut

our %instantiate_for = (
    #these are anonymous subroutines because I couldn't figure out how to sanely get a reference to an inherited method
    sample       => sub { $_[0]->model("ViroDB::Sample")->find($_[1]) },
    'sample.rna' => sub { $_[0]->model("ViroDB::Sample")->find($_[1]) },
    'sample.dna' => sub { $_[0]->model("ViroDB::Sample")->find($_[1]) },
    extraction   => sub {Viroverse::Model::extraction->retrieve($_[1]) },
    'extraction.rna' => sub {Viroverse::Model::extraction->retrieve($_[1]) },
    'extraction.dna' => sub {Viroverse::Model::extraction->retrieve($_[1]) },
    rt_product     => sub {Viroverse::Model::rt->retrieve($_[1]) },
    rt                 => sub {Viroverse::Model::rt->retrieve($_[1]) },
    pos_pcr      => sub {Viroverse::Model::pcr->retrieve($_[1]) },
    pcr_more     => sub {Viroverse::Model::pcr->retrieve($_[1]) },
    pcr_pool     => sub {Viroverse::Model::pcr->retrieve($_[1]) },
    pcr          => sub {Viroverse::Model::pcr->retrieve($_[1]) },
    gel          => sub {Viroverse::Model::gel->retrieve($_[1]) },
    clone        => sub {Viroverse::Model::clone->retrieve($_[1]) },
    dna_sequence => sub {Viroverse::Model::sequence::dna->retrieve($_[1])},
    special_label=> sub {return Viroverse::Model::gel_lane::special->new($_[1]) },
    alignment     => sub {Viroverse::Model::alignment->retrieve($_[1]) },
    aliquot          => sub {Viroverse::Model::aliquot->retrieve($_[1]) },
    found_aliquots   => sub {Viroverse::Model::aliquot->retrieve($_[1]) },
    bisulfite_converted_dna => sub {Viroverse::Model::bisulfite_converted_dna->retrieve($_[1]) },
);


=item find_a
    looks up a registered type of object
=cut 

sub find_a {
    my ($self, $context) = @_;

    my ($what,$which) = @{$context->req->args};

    unless ($what && $which) {
        $context->detach('mk_error',['need to know what kind and which object to return']);
    }

    return $context->detach('mk_error', ["Unknown type '$what'"])
        unless ref $instantiate_for{$what} eq 'CODE';

    return $instantiate_for{$what}($context,$which);
}

=item which_package
    Returns the package name for an english name for an object (eg 'Viroverse::sample' for 'sample')
=cut
sub which_package {

    my %package_of = (
        sample        => 'Viroverse::sample',
        'sample.rna'  => 'Viroverse::sample',
        'sample.dna'  => 'Viroverse::sample',
        extraction    => 'Viroverse::Model::extraction',
        'extraction.rna' => 'Viroverse::Model::extraction',
        'extraction.dna' => 'Viroverse::Model::extraction',
        rt_product    => 'Viroverse::Model::rt',
        rt          => 'Viroverse::Model::rt',
        bisulfite_converted_dna => 'Viroverse::Model::bisulfite_converted_dna',
        pos_pcr       => 'Viroverse::Model::pcr',
        pcr_more      => 'Viroverse::Model::pcr',
        pcr           => 'Viroverse::Model::pcr',
        gel           => 'Viroverse::Model::gel',
        clone         => 'Viroverse::Model::clone',
        dna_sequence  => 'Viroverse::Model::sequence::dna',
        #special_label => 'Viroverse::Model::gel_lane::special',
        chromat          => 'Viroverse::Model::chromat',
        alignment       => 'Viroverse::Model::alignment',
    );
    return $package_of{$_[1]};
}

=head1 AUTHORS

Brandon Maust

=cut

1;
