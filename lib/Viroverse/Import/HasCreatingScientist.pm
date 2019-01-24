use strict;
use warnings;
use utf8;
use 5.018;

package Viroverse::Import::HasCreatingScientist;
use Moo::Role;
use Viroverse::Types -types;
use namespace::clean;

=head1 NAME

Viroverse::Import::HasCreatingScientist - Provides a creating_scientist
attribute for Viroverse::Import consumers

=head1 ATTRIBUTES

=head2 creating_scientist

A L<ViroDB::Result::Scientist>, generally treated as the acting user in
L</process_row>, if per-row scientists aren't available.

=cut

has creating_scientist => (
    is => 'ro',
    isa => ViroDBRecord["Scientist"],
    coerce => 1,
    required => 1,
);

1;
