use 5.018;
use strict;
use warnings;
use utf8;

=encoding UTF-8

=head1 NAME

Viroverse::Search::Faceted - A role for faceted record searches

=head1 SYNOPSIS

    # Viroverse::Search::Sequence uses Viroverse::Search::Faceted
    #
    my $search = Viroverse::Search::Sequence->new(
        query => {
            tissue_type => "brain"
        }
    );
    
    say "Matched ", $search->count, " sequences";
    
    # First 10 results, as ViroDB::Result::SequenceSearch objects
    my @results = $search->results;

=cut

package Viroverse::Search::Faceted;
use Moo::Role;
use Clone qw< clone >;
use List::Util 1.29 qw< pairmap pairgrep >;
use Ref::Util qw< is_arrayref >;
use Types::Common::Numeric qw< :types >;
use Types::Common::String qw< :types >;
use Types::Standard qw< :types >;
use Viroverse::Logger qw< :log :dlog >;
use namespace::clean;

=head1 SEARCH ATTRIBUTES

These attributes define the search parameters and should be provided at object
construction.

=head2 query

A hashref of field-value pairs for searching.  Values may be strings or
arrayrefs of strings.  The empty string represents null, or unknown, values.
See L</SEARCH FIELDS> below for what keys are valid.

=head2 model

An instance of L<DBIx::Class::ResultSet>.

Normally built automatically, so you shouldn't need to pass this in.

=head2 rows

Number of rows to return from L</results>.  Defaults to 12.

=head2 page

Page number of rows to return from L</results>.  Defaults to 1.  Page size is
set by L</rows>.

=cut

has model => (
    is      => 'lazy',
    isa     => InstanceOf['DBIx::Class::ResultSet'],
    builder => '_build_model',
);
requires '_build_model';

has rows => (
    is      => 'ro',
    isa     => PositiveInt,
    default => sub { 12 },
);

has page => (
    is      => 'ro',
    isa     => PositiveInt,
    default => sub { 1 },
);

has query => (
    is       => 'ro',
    isa      => HashRef,
    required => 1,
);


=head1 RESULT ATTRIBUTES

These attributes perform the search queries and return information about the
results.

=head2 resultset

Returns a L<DBIx::Class::ResultSet> with the search attributes of this object
applied to constrain the results.

=head2 count

Returns the number of records found.

=head2 ids

Returns an arrayref of all record IDs found.

=head2 facets

Returns a hashref of name-value pairs for each facetable field (see L</SEARCH
FIELDS>) in the results.  Each value is a hashref like the following:

    Dict[
        name    => "field name",
        label   => "humanized label",
        values  => ArrayRef[
            Tuple[ "field value", PositiveOrZeroInt ]
        ]
    ]

The the (value, count) tuples represent the number of times that value occurs
for the field in the results.

=head2 results

Applies ordering to L</resultset> and returns a page of rows as determined by
L</rows> and L</page>.  In list context, returns a list of record objects.  In
scalar context returns a resultset object of the same.

Results are ordered according to the consuming class.  Please see its own
documentation.

=cut

has resultset => (
    is  => 'lazy',
    isa => InstanceOf['DBIx::Class::ResultSet'],
);

has count => (
    is  => 'lazy',
    isa => PositiveOrZeroInt,
);

has ids => (
    is  => 'lazy',
    isa => ArrayRef[ PositiveOrZeroInt ],
);

has facets => (
    is  => 'lazy',
    isa => HashRef[
        Dict[
            name    => NonEmptySimpleStr,
            label   => NonEmptySimpleStr,
            values  => ArrayRef[
                Tuple[ SimpleStr, PositiveOrZeroInt ]
            ],
        ],
    ],
);

sub results {
    my $self = shift;
    my %opts = @_;
    return $self->resultset->search({}, {
        rows     => $self->rows,
        page     => $self->page,
        order_by => $self->_order_by,
    });
}


=head1 SEARCH FIELDS

Consuming classes define the accepted search fields which may be keys in
L</query>.

Restrictions between different fields are ANDed while multiple values for a
single field are ORed.

Please see L<Viroverse::Search::Sequence/SEARCH FIELDS> for an example.

=head1 REQUIRED METHODS

This section documents the required methods which consumers of this role must
implement.  You do not need to care about these implementation details unless
you're writing a new search class or modifying an existing one.

Please see L<Viroverse::Search::Sequence> for example implementations of these
methods.

=head2 _build_query_fields

Attribute builder for C<_query_fields>.

Defines what query fields the search class accepts and how those query fields
translate into search methods on the L<DBIx::Class::ResultSet> L</model> and
how to generate facet values for each field.

Must return a hash ref defining query field names as keys and a metadata hash
refs as values.  The metadata hash ref can contain the following keys, and in
most cases must always include C<method>:

=over 4

=item method

Required if C<facet> is not provided, otherwise optional though typically still
functionally necessary for most fields.  Names the resultset method to call
with a list of query values.  This method should apply search conditions to the
resultset and return a newly restricted resultset.

=item facet

Required if C<method> is not provided, otherwise optional.  If provided, then
search results will be faceted by the query field.  The value for this key is
another hash ref which must contain the following keys:

=over 4

=item column

Required.  Defines how to produce a value to group by for tabulating counts by
value.  For most columns this is a simple string, but it may be any valid
construct for L<DBIx::Class::ResultSet/select>.

=item label

Required.  A human-friendly name for this query field which is provided in the
data returned by L</facets>.  Unlike non-facetable query fields which will
often have their own bespoke UI handling (and thus the UI can set appropriate
labels), facets more naturally share UI handling and doing so is facilitated by
providing a label with the data.

=back

=item values

Optional.  May only be used in combination with C<method>.  A code ref to
generate or transform query values for this query field.

The code ref is passed a normalized copy of the L</query> hashref and should
return an array ref or undef.  The return value, if defined, will be passed to
C<method> when performing the search in place of any values which were under
this field's key in L</query>.

See the implementation of L<Viroverse::Search::Sample> for an example usage.

=back

=cut

my $Facet = Dict[
    column => ScalarRef[ArrayRef] | NonEmptySimpleStr,
    label  => NonEmptySimpleStr,
];

my $QueryField =
    Dict[ method => NonEmptySimpleStr ]
  | Dict[ method => NonEmptySimpleStr, facet  => $Facet ]
  | Dict[ method => NonEmptySimpleStr, values => CodeRef ]
  | Dict[ facet  => $Facet ];

has _query_fields => (
    is  => 'ro',
    isa => Map[ NonEmptySimpleStr, $QueryField ],
    builder => '_build_query_fields',
);


=head2 _build_id_field

Attribute builder for C<_id_field>.

Must return a non-empty string which is the method name of the accessor for the
desired I<numeric> id field of the resultset record objects.

The field name specified by C<_id_field> is used when building the L</ids>
attribute.

=cut

has _id_field => (
    is      => 'ro',
    isa     => NonEmptySimpleStr,
    builder => '_build_id_field',
);


=head2 _build_order_by

Attribute builder for C<_order_by>.

Must return an array ref of valid
L<SQL::Abstract order by clauses|SQL::Abstract/ORDER BY CLAUSES>
suitable for passing to L<DBIx::Class::ResultSet/order_by>.

These clauses specify the sort order of the search L</results>.

=cut

has _order_by => (
    is      => 'ro',
    isa     => ArrayRef[
          Dict[ -asc  => ArrayRef | Str ]   # { -asc  => ... }
        | Dict[ -desc => ArrayRef | Str ]   # { -desc => ... }
        | ScalarRef[ArrayRef]               # \[...]
    ],
    builder => '_build_order_by',
);

requires '_build_query_fields';
requires '_build_id_field';
requires '_build_order_by';

sub _build_resultset {
    my $self = shift;
    my $rs   = $self->_apply_query_to_model( $self->_query_fields );
    Dlog_debug { "Built search: $_" } $rs->as_query;
    return $rs;
}

sub _apply_query_to_model {
    my $self    = shift;
    my $mapping = shift || {};
    my $model   = $self->model;
    my $query   = $self->_apply_query_fields( $mapping );

    # Filter the given search parameters (query) to those that we know and
    # allow (via $mapping) and construct a set of (resultset method, value)
    # tuples for each parameter.
    my @constraints =
         pairmap { [$mapping->{$a}{method}, $b] }
        pairgrep { $mapping->{$a}{method} and defined $b }
                 %$query;

    # For each query constraint, call the resultset method registered in the
    # query field mapping with the set of values.  Chain iteratively from our
    # base model to produce the final, fully-constrained resultset object.
    my $rs = $model;
    for (@constraints) {
        my ($method, $value) = @$_;
        $rs = $rs->$method(@$value);
    }
    return $rs;
}

sub _apply_query_fields {
    my $self    = shift;
    my $mapping = shift || {};
    my $query   = clone($self->query);

    my $normalize = sub {
        my $v = shift;
           $v = [$v] unless is_arrayref($v);

        return [
            # Convert empty strings to undefs, with the expectation they'll
            # become SQL NULLs.  This helps consumers since it may not be
            # possible to explicitly pass a null value over a form submission,
            # but the concept of a non-existent/unknown value is important for
            # searching (e.g. what sequences have an unknown nucleic acid
            # type?).  At the same time, it's unlikely that the empty string
            # itself is ever going to be a meaningful value by which to search
            # for things.
            map { length($_) ? $_ : undef }
                @$v
        ];
    };

    # Remove any query fields for which we don't have a mapping.  These are
    # either invalid or temporarily masked for collecting facet values.
    delete $query->{$_}
        for grep { not $mapping->{$_} } keys %$query;

    # Normalize all static query values
    $query->{$_} = $normalize->( $query->{$_} )
        for keys %$query;

    # Compute any query values which are generated dynamically via the mapping
    # or have special-normalization
    $query->{$_} = $mapping->{$_}{values}->( $query )
        for grep { $mapping->{$_}{values} } sort keys %$mapping;

    # Query values which are bare undefs at this point should be removed, as
    # they're equivalent to not passing in the field at all.  Undefs which were
    # explicitly passed in should be wrapped in an arrayref already.
    delete $query->{$_}
        for grep { not defined $query->{$_} } keys %$query;

    return $query;
}

sub _build_count {
    my $self = shift;
    return $self->resultset->count + 0;
}

sub _build_ids {
    my $self = shift;
    my $id   = $self->_id_field;
    my @rows = $self->resultset->search({}, {
        columns  => [ $id ],
        order_by => { -asc => $id },
    });
    return [ map { $_->$id + 0 } @rows ];
}

sub _build_facets {
    my $self   = shift;
    my $facets = { };

    my $query_fields = $self->_query_fields;

    for my $name (keys %$query_fields) {
        my $facet = $query_fields->{$name}{facet}
            or next;

        my ($column, $label) = @$facet{qw[ column label ]};

        # Remove current facet from search conditions so we get a count of this
        # facet's full values before restriction.  This is nicer for the UX,
        # and allows multiple values per facet to be selected.
        delete local $query_fields->{ $name };

        my $values = $self->_apply_query_to_model( $query_fields );
        $values = $values->search({}, {
            columns  => [
                { $name => $column },
                { count => { COUNT => 1 } },
            ],
            group_by => [ $column ],
            order_by => [ { -desc => "count" } ],
        });

        Dlog_debug { "Built facet search for «$name»: $_" } $values->as_query;

        $facets->{ $name } = {
            name   => $name,
            label  => $label,
            values => [
                map { [ $_->get_column($name) // "", $_->get_column("count") + 0 ] }
                    $values->all
            ],
        };
    }

    return $facets;
}

1;
