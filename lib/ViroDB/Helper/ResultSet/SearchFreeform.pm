use utf8;
use strict;
use warnings;
package ViroDB::Helper::ResultSet::SearchFreeform;
use MooseX::Role::Parameterized;
use Types::Standard qw< :types >;
use Types::Common::String qw< NonEmptyStr >;
use Regexp::Common qw< delimited >;
use Viroverse::Logger qw< :dlog >;
use namespace::autoclean;

=encoding UTF-8

=head1 NAME

ViroDB::Helper::ResultSet::SearchFreeform - Provides a search_freeform method
for subclasses of DBIx::Class::ResultSet

=head1 DESCRIPTION

This class is a parameterized role intended to be consumed by
L<DBIx::Class::ResultSet> subclasses.  It is intended to provide support for a
basic freeform-text search over a result set.

=head1 PARAMETERS

=head2 text_fields

Required.  An array ref of field names to match against.

=head2 id_field

Required.  The name of an id field (usually numeric) for this result set, for
matching id-like search terms.

A code ref may be provided for more advanced usages, such as conditional
matching or matching on a multi-part id.  The code reference is passed the
L<alias of the current result source|DBIx::Class::ResultSet/current_source_alias>
as the first value and a key-value list of named matches from the
L</id_pattern> regular expression.  See L<ViroDB::ResultSet::SequenceSearch>
for an example.

=head2 id_pattern

Optional.  A regular expression pattern (from C<qr//>) which matches search
tokens that look like ids.  The pattern must include a named match called "id".

The default matches search terms which are entirely numeric.

=head1 PROVIDES

=head2 search_freeform

Limits the current result set based on the search text provided to it.

Takes a list of strings, each of which is split into whitespace-separated
search terms.  Terms may include whitespace by surrounding the term in double
quotes.  Each term is required to match at least one of the parameterized
L</text_fields> using a case-insensitive containment comparison
(C<ILIKE '%…%'>).  Terms which match L</id_pattern> are additionally compared
for equality to L</id_field>, which may satisify a match for that term.  All
terms in a single search string are ANDed together.  Multiple search
strings are ORed together.

Returns a new result set.

=cut

parameter text_fields => (
    isa      => ArrayRef[ NonEmptyStr ],
    required => 1,
);

parameter id_pattern => (
    isa      => RegexpRef,
    default  => sub { qr/^ (?<id>\d+) $/x },
);

parameter id_field => (
    isa      => NonEmptyStr | CodeRef,
    required => 1,
);

role {
    my $p = shift;

    requires 'current_source_alias';
    requires 'search';

    method "search_freeform" => sub {
        my $self = shift;
        my $me   = $self->current_source_alias;
        my @conditions;

        for my $query (@_) {
            next unless defined $query
                    and $query =~ /\S/;

            my (@tokens, @token_conditions);
            my $original_query = $query;

            # Extract either quoted or unquoted whitespace-separated tokens, in
            # order, one at a time.  Unbalanced quotes are ignored.
            my $token_pattern = qr/
                (?| $RE{delimited}{-delim=>'"'}{-keep}
                  | ((?#1)) ((?#2)) ((?#3)[^\s"]+) )    # Burns two capture groups so that our matched
                                                        # text is in $3, like the Regexp::Common pattern.
            /x;
            push @tokens, $3
                while $query =~ /$token_pattern/g;

            Dlog_debug { "Tokenized «$original_query» as: $_" } \@tokens;

            for my $token (@tokens) {
                my @fields;

                # Special-case anything that looks like an id
                if ($token =~ $p->id_pattern) {
                    my %match = %+;
                    my $field = $p->id_field;
                    push @fields, ref $field eq 'CODE'
                        ? $field->($me, %match)
                        : { "$me.$field" => $match{id} };
                }

                # Search text fields for containment of the token
                $token =~ s/(?=[_%\\])/\\/g;  # escape meta chars
                $token =~ s/^|$/%/g;          # surround by % for contains

                push @fields, { "$me.$_" => { ILIKE => $token } }
                    for @{ $p->text_fields };

                # All possibilities for a single token get OR'd
                push @token_conditions, { -or => \@fields }
                    if @fields;
            }

            # All tokens get AND'd
            push @conditions, { -and => \@token_conditions }
                if @token_conditions;
        }

        # All input strings get OR'd, matching other methods
        return @conditions
            ? $self->search({ -or => \@conditions })
            : $self;
    };
};

1;
