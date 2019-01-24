use strict;
use warnings;
use utf8;

package Viroverse::SampleTree;
use Moo;
use Types::Standard -types;
use Type::Utils qw< union >;
use Viroverse::Logger qw< :log >;

my $treenode = union [
        ConsumerOf["Viroverse::SampleTree::Node"],
        InstanceOf["ViroDB::Result::Patient"],
        InstanceOf["Viroverse::SampleTree::MissingSteps"]
    ];

has 'current_node' => (
    is       => 'ro',
    isa      => $treenode,
    required => 1
);

has 'intended_sample' => (
    is        => 'ro',
    isa       => Maybe[InstanceOf['ViroDB::Result::Sample']],
);

has 'path' => (
    is => 'lazy',
    isa => ArrayRef[$treenode],
);

has 'primogenitor' => (
    is => 'lazy',
    isa => $treenode,
    builder => sub { return $_[0]->path->[0] },
);

has 'current_node_depth' => (
    is => 'lazy',
    isa => Int,
    builder => sub { return @{$_[0]->path} - 1 },
);

sub _walk_up_from {
    my ($self, @path) = @_;
    while ($path[0]->can("parent") && $path[0]->parent) {
        unshift @path, $path[0]->parent;
    }
    return @path;
}

sub _build_path {
    my $self = shift;
    my @path = $self->_walk_up_from($self->current_node);

    if ($self->intended_sample) {
        my @samples =  grep { $_->isa("ViroDB::Result::Sample") } @path;
        if (grep { $_->id == $self->intended_sample->id } @samples) {
            log_debug { "Sample ancestry checks out" };
        } elsif (@samples) {
            log_error {[ "Ancestry mismatch for %s: %s",
                         ref $self->current_node,
                         $self->current_node->id ]};
            log_error {[ "Intended sample: %s; actual ancestor sample: %s",
                         $self->intended_sample->id,
                         $samples[0]->id ]};
            die "Encountered ancestry mismatch";
        } else {
            log_debug { "Ancestry never reached a sample; fix it up" };
            unshift @path, (bless {}, "Viroverse::SampleTree::MissingSteps");
            unshift @path, $self->_walk_up_from($self->intended_sample);
        }
    }
    return \@path;
}

1;
