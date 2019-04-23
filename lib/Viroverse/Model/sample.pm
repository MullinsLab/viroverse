package Viroverse::Model::sample;
use base 'Viroverse::CDBI';
use Viroverse::sample;
use Carp qw[carp croak];
use ViroDB;
use strict;
use 5.018;

=head1 NAME

Viroverse::Model::sample -- provide Viroverse::samples to Catalyst

=cut

__PACKAGE__->table('viroserve.sample');
__PACKAGE__->columns(Primary => 'sample_id');
__PACKAGE__->columns(All => qw/sample_id vv_uid name/);

sub sequences {
    my $self = shift;
    return Viroverse::Model::sequence::dna->search_by_sample($self->give_id);
}

=head2 to_string

Proxy for L<ViroDB::Result::Sample/to_string> that wraps up getting a
L<ViroDB::Result::Sample> object.

=cut

sub to_string {
    my $self    = shift;
    my $db      = ViroDB->instance;
    my $sample  = $db->resultset("Sample")->find($self->sample_id) or return undef;
    return $sample->to_string;
}

1;
