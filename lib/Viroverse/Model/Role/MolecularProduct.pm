use strict;
use warnings;

package Viroverse::Model::Role::MolecularProduct;

use Moose::Role;
use Viroverse::Infer::SequenceType;
use namespace::autoclean;

with 'Viroverse::SampleTree::Node';

requires 'input_product';

# NOTE: The consumers of the MolecularProduct role are no longer relying on
# Viroverse::sample to lead to sample records, which is good, but it still
# makes sense to leave the base-cases of the role methods (for
# ViroDB::Result::Sample) in this role. Until this role is obsoleted by
# converting extractions and other downstream products into delta samples and
# derivations, each of those things expects input_sample to be the ancestral
# sample with the greatest depth, not the least.  -- silby@ 2016-09-09

sub input_sample {
    my $self  = shift;
    my $input = $self->input_product;
    return $input->isa("ViroDB::Result::Sample") ? $input               :
           $input->can("input_sample")           ? $input->input_sample :
           $input->can("sample_id")              ? $input->sample_id    :
           undef
           ;
}

sub parent { $_[0]->input_product };

sub children { () };

sub preferred_sequence_type {
    my $self = shift;
    return Viroverse::Infer::SequenceType
        ->new( sequenced_product => $self )
        ->best_guess;
}

sub preferred_sequencing_na_type {
    my $self = shift;
    my $input = $self->input_product;
    my %sample_type_map = (
        cells     => "DNA",
        RNA       => "RNA",
        synthetic => undef,
    );
    if ($input->isa("ViroDB::Result::Sample")) {
        if (defined $input->sample_type) {
            return $sample_type_map{$input->sample_type->name};
        } else {
            return "DNA";
        }
    }
    return $input->preferred_sequencing_na_type;
}

1;
