package Viroverse::View::TT;

use strict;
use base 'Catalyst::View::TT';
use Template::Stash;
use Viroverse::Config;
use Scalar::Util ();

# Work around the absurdity that is the behaviour of TT's .size vmethod and the
# lack of any way to force list context without exploding a hashref (hash.list
# == hash.pairs, at least until TT3, at which point I hope we're not using TT
# anymore).  We could use Template::Plugin::ArrayRef, but [% foo.count %] is
# nicer than [% foo.arrayref.size %].
#
# Another workaround is [% foo.max + 1 %] since TT will transform a scalar or
# hash into a single element list first (since .max is only on lists unlike
# .size).  It doesn't require these new vmethods, but it's really verbose and
# unclear.
# -trs, 18 Oct 2013
#
# The issue is really with model methods that return a list of records.  If
# that list contains at least two records, it's an array in TT's eyes and .size
# will work as expected.  If that list only contains one record, it's a hash in
# TT's eyes, and .size will return the number of keys.  This isn't desirable
# behaviour.  However, sometimes .size is used knowingly on a hash to get a
# count of keys (instead of the more explicit .keys.size).  In this case,
# .count will DTRT depending on the blessed-ness of the hash.
# -trs, 1 Nov 2013
Template::Stash->define_vmethod( 'scalar',
    count => sub { defined $_[0] ? 1 : 0 }
);
Template::Stash->define_vmethod( 'hash',
    count => sub { Scalar::Util::blessed($_[0]) ? 1 : scalar keys %{$_[0]} }
);
Template::Stash->define_vmethod( 'array',
    count => sub { scalar @{$_[0]} }
);

# A .map vmethod for convenience and ease of porting over to Template::Alloy later
Template::Stash->define_vmethod( 'array',
    map => sub {
        my ($array, $field) = @_;
        map {
            Scalar::Util::blessed($_) ?   $_->$field :
                        ref eq 'HASH' ? $_->{$field} :
             die "array value isn't an object or hash"
        } @$array
    }
);

__PACKAGE__->config({
    LOAD_PERL => 1,
    FILTERS => {
        none => sub { $_[0] },   # Compat with our Template::Alloy view
    },
});

=head1 NAME

Viroverse::View::TT - subclassed Catalyst View to render Template Toolkit results

=head1 SYNOPSIS

See L<Catalyst::View::TT>

=head1 DESCRIPTION

Catalyst TT View.

=head1 AUTHOR

Brandon Maust

=cut

=head1 OVERRIDDEN METHODS

=item process
=cut
sub process {
    my ($self, $context) = @_;

    while ( my ($key,$value) = each %{Viroverse::Config->conf->{template_defaults}}) {
        warn "overwriting existing stash value for $key with $value" if exists $context->stash->{$key};
        $context->stash->{$key} = $value;
    }

    $self->SUPER::process($context);
}

sub template_exists {
    my ($self, $template) = @_;
    return scalar grep { -r "$_/$template" } @{ $self->include_path };
}

1;
