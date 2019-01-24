use strict;
use warnings;
use utf8;
use 5.018;

package Viroverse::Infer::SequenceType;
use Moo;
use List::Util 1.33 qw< any >;
use Safe::Isa qw< $_call_if_object >;
use Scalar::Util qw< blessed >;
use Types::Standard qw< :types >;
use Viroverse::Logger qw< :log :dlog >;
use Viroverse::Types qw< :types >;
use namespace::clean;

has sequenced_product => (
    is      => 'ro',
    isa     => Maybe[ConsumerOf['Viroverse::SampleTree::Node']],
    requird => 1,
);

has best_guess => (
    is       => 'lazy',
    isa      => ViroDBRecord["SequenceType"],
    init_arg => undef,
);

sub _build_best_guess {
    my $self  = shift;
    my $input = $self->sequenced_product
        or return type("Genomic");

    # Note that the ISLA type is never automatically inferred for now, because
    # we don't have the PCR/primer information to do so.
    #   -trs, 21 July 2017

    # We always need to walk the whole ancestry chain, so just do it once.
    my @ancestry = $input;
    my $parent;
    push @ancestry, $parent
        while $ancestry[-1]
          and $ancestry[-1]->DOES("Viroverse::SampleTree::Node")
          and $parent = $ancestry[-1]->parent;

    Dlog_debug { "Ancestry chain: $_" } [ map { [blessed $_, $_->id] } @ancestry ];

    return type("Bisulfite")
        if any { $_->isa("Viroverse::Model::bisulfite_converted_dna") } @ancestry;

    return type("Integration site")
        if any {
                $_->isa("Viroverse::Model::pcr")
            and ($_->round // 0) == 1
            and any { $_ eq "HIV-1" } map { $_->organism->$_call_if_object("name") } $_->primers
            and any { $_ eq "human" } map { $_->organism->$_call_if_object("name") } $_->primers
        } @ancestry;

    return type("Genomic");
}

sub type {
    my $name = shift;
    ViroDB->instance->resultset("SequenceType")->find({ name => $name })
        or Dlog_fatal { "Couldn't find SequenceType $_" } $name;
}

1;
