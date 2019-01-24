use strict;
use warnings;

package ViroDB::InflateColumn::JSON;
use base 'DBIx::Class';
use JSON::MaybeXS;
use namespace::clean;

=head1 NAME

ViroDB::InflateColumn::JSON - Automatically inflate/deflate json and jsonb types

=head1 SYNOPSIS

    __PACKAGE__->load_components("+ViroDB::InflateColumn::JSON");

=head1 DESCRIPTION

Uses L<DBIx::Class::InflateColumn> to filter C<json> and C<jsonb> type columns
to and from Perl hashes.

The filter handler is automatically added during column registration, via a
chained call on C<register_column>.

=cut

__PACKAGE__->load_components("InflateColumn");

sub register_column {
    my ($self, $column, $info, @rest) = @_;

    $self->next::method($column, $info, @rest);
    return unless $info->{data_type} =~ /^jsonb?$/i;

    $self->inflate_column($column, {
        inflate => sub { JSON::MaybeXS->new->decode($_[0]) },
        deflate => sub { JSON::MaybeXS->new->encode($_[0]) },
    });

    return;
}

1;
