package Viroverse::View::JSON;

use strict;
use warnings;
use base 'Catalyst::View';
use JSON::MaybeXS;
use Data::Dump;

my $jason = JSON->new->allow_unknown;

=head1 NAME

Viroverse::View::JSON - Catalyst View

=head1 SYNOPSIS

See L<Viroverse>

=head1 DESCRIPTION

Catalyst View.

=head1 AUTHOR

Brandon Maust

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

=head1 METHODS

=item process

Converts items in the 'jsonify' key of the stash to JSON notation.  The corresponding javascript object is assigned to 'json_result'
or the value of 'jsonify_var_name' if included in the stash.

NOTE: the underlying JSON library doesn't like blessed objects, so what's passed in should be bare hashes.  C<Acme::Damn> may come in handy for that.

=cut

sub process {

    my ($self, $c ) = @_;

    my $var_name = $c->stash->{jsonify_var_name} || 'var json_result';

    $c->response->content_type('text/javascript; charset=utf-8');

    my $obj_ref = $c->stash->{'jsonify'};
    my @objs;

    # XXX TODO: Oh god, fix this ridiculousness.
    foreach my $id (keys %{$obj_ref}) {
        push @objs, "\"$id\":".$jason->encode($obj_ref->{$id});
    }
    my $obj_str = "$var_name = {"
        .join(',',@objs)
        ."}\n";
    $obj_str =~ s/},/},\n/g;

    $c->response->body($obj_str);

    return 1;
}

sub y {
    my ($self, $c ) = @_;

    $c->response->content_type('text/javascript; charset=utf-8');
    my $obj_ref = $c->stash->{'jsonify'};

    # XXX TODO: And this!
    my $obj_str = '{"Response": '
        .$jason->encode($obj_ref)
        ."}\n";
    $obj_str =~ s/},/},\n/g;

    $c->response->body($obj_str);

    return 1;

}

1;
