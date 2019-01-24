use strict;
use warnings;
use utf8;

package Viroverse::Controller::Download;
use base 'Viroverse::Controller';
use 5.010;

=head1 NAME

Viroverse::Controller::download - Download of database objects

=head1 DESCRIPTION

Endpoints for download of data from Viroverse for external use.

=cut

use Viroverse::Model::sequence::dna;
use Viroverse::Model::chromat;

use Catalyst::ResponseHelpers;
use Path::Tiny;
use List::AllUtils qw< uniq >;

sub base : Chained('/') PathPart('download') CaptureArgs(0) { }

=head1 METHODS

=head2 sidebar_sequences

Bound to C</download/sidebar/sequences>.

Responds with a FASTA of sequences currently stored in the sidebar
C<dna_sequence> slot.  See L</_sequences> for a description of naming
parameters.

=head2 sequences

Bound to C</download/sequences>.

Responds with a FASTA of sequences requested in the C<seq_ids> parameter.
Multiple values may be provided by specifying the field multiple times or using
commas in a single parameter value.  See L</_sequences> for a description of
naming parameters.

=head2 _sequences

Private.

Helper method which generates a FASTA response from the sequence ids passed as
arguments.

Three request parameters control the naming of sequences in the FASTA:

=over

=item * name_parts

Multi-valued parameter which specifies a list of keys from
L<Viroverse::Model::sequence/name_parts>.  The default is handled by
L</fasta_description>.

=item * sep

Delimiter to use to separate each part of the name, may be multi-character.
Defaults to C<|>.

=item * replace_spaces

If set to an underscore (C<_>), runs of whitespace are replaced by an
underscore in each part of the name.

If set to another true value, runs of whitespace are removed in each part of
the name.

If set to a false value, no whitespace replacement is performed.

Defaults to false.

=back

=cut

sub sidebar_sequences : Chained('base') PathPart('sidebar/sequences') Args(0) {
    my ($self, $c) = @_;
    $self->_sequences($c, @{ $c->session->{sidebar}{dna_sequence} });
}

sub sequences : Chained('base') PathPart('sequences') Args {
    my ($self, $c) = @_;
    $self->_sequences($c, map { split /,/ } $c->req->param('seq_ids'));
}

sub _sequences : Private {
    my ($self, $context, @ids) = @_;
    my @seqs = Viroverse::Model::sequence::dna->retrieve_many(uniq @ids);
    my $date = DateTime->today->ymd;
    my $replace_spaces = $context->req->param('replace_spaces') || "";

    my %naming = (
        name    => [ $context->req->param('name_parts') ],
        sep     => (scalar $context->req->param('sep') || '|'),
        filter  => (
            $replace_spaces eq "_" ? sub { s/\s+/_/gr } :
            $replace_spaces        ? sub { s/\s+//gr  } :
                                                  undef ),
    );

    my $filename = @seqs == 1
        ? $seqs[0]->fasta_description(%naming, sep => "-", filter => sub { s/[^A-Za-z0-9_.-]+/_/gr })
        : "viroverse-$date";

    $context->response->content_type('text/plain');
    $context->response->header('Content-Disposition' => "attachment; filename=$filename.fasta");
    $context->response->write( $_->get_FASTA(%naming) ) for @seqs;
}

sub chromat : Chained('base') PathPart('chromat') Args(1) {
    my ($self, $context, $chromat_id) = @_;

    my $chromat = Viroverse::Model::chromat->retrieve($chromat_id)
        or return NotFound($context, "Chromat «$chromat_id» not found");

    $context->response->content_type('application/octet-stream');
    $context->response->header('Content-Disposition' => "attachment");
    $context->response->write( $chromat->data );
}

sub chromat_with_name : Chained('base') PathPart('chromat') Args(2) {
    shift->chromat(@_)
}

1;
