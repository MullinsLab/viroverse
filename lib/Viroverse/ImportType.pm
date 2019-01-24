use strict;
use warnings;
use utf8;
use 5.018;

package Viroverse::ImportType;
use Moo;
use Carp qw< confess >;
use List::Util 1.29 qw< pairmap >;
use Module::Pluggable::Object;
use Module::Runtime qw< module_notional_filename >;
use Pod::Abstract;
use Types::Common::String qw< :types >;
use Types::Standard qw< :types >;
use Viroverse::Types qw< :types >;
use namespace::clean;

=head1 NAME

Viroverse::ImportType - Information about Viroverse::Import importers

=head1 SYNOPSIS

    # Where $job is a ViroDB::Result::ImportJob
    $job->type       # An instance of this class

    my $type = Viroverse::ImportType->new( name => "NumericLabResults" );
    $type->package;  # Viroverse::Import::NumericLabResults
    $type->label;    # Numeric Lab Results
    $type->help_pod;

    my @types = Viroverse::ImportType->load_all;

=head1 DESCRIPTION

Most of the time you'll use instances of this class via
L<ViroDB::Result::ImportJob> records, where calling the
L<type method|ViroDB::Result::ImportJob/type> returns the appropriate object.

As in the synopsis above, however, you can also use this class to either:

=over

=item * fetch information about a particular import type by providing the
L</name> attribute to the constructor

=item * fetch information about all import types by calling the L</load_all>
static method

=back

B<All instances of this class are singletons keyed on the package name.>

=head1 ATTRIBUTES

All of the useful information provided by instances of this class is stored in
attributes.

=head2 package

The full package name of this import type.

Required for instantiation if L</name> isn't provided.  Coercible from an
abbreviated package name.

Read-only.

=cut

has package => (
    is      => 'ro',
    isa     => ImporterClass,
    coerce  => 1,
    lazy    => 1,
    builder => sub {
        "Viroverse::Import::" . shift->name
    },
);


=head2 name

The short name for this import type.  This value is often used as a key to
identify the import type.

Required for instantiation if L</package> isn't provided.

Read-only.

=cut

has name => (
    is      => 'ro',
    isa     => NonEmptySimpleStr,
    lazy    => 1,
    builder => sub {
        shift->package =~ s/^Viroverse::Import:://r
    },
);


=head2 label

A descriptive, human-friendly label for this import type.  The default is a
transformation of L</name>.

Read-write.  Writer is C<set_label>.  Only L<Viroverse::Import> consumers
should set this via their L<metadata class method|Viroverse::Import/metadata>.

=cut

has label => (
    is      => 'rw',
    isa     => NonEmptySimpleStr,
    writer  => "set_label",
    lazy    => 1,
    builder => sub {
        shift->name =~ s/(?<!^)(?=[A-Z][a-z])/ /gr
    },
);


=head2 primary_noun

A word identifying the primary record type that this importer deals with.
Currently one of the strings C<sample>, C<sequence>, or C<other>.

Read-write.  Writer is C<set_primary_noun>.  Only L<Viroverse::Import>
consumers should set this via their L<metadata class method|Viroverse::Import/metadata>.

=cut

has primary_noun => (
    is      => 'rw',
    isa     => Maybe[NonEmptySimpleStr],
    writer  => "set_primary_noun",
    lazy    => 1,
    builder => sub {
        my $self = shift;
        return "sample"   if $self->name =~ /sample/i;
        return "sequence" if $self->name =~ /sequence/i;
        return undef;
    },
);


=head2 help_pod

The POD contents (as a string) of the DESCRIPTION section in the import type's
package file.

Read-only.

=cut

has help_pod => (
    is  => 'lazy',
    isa => NonEmptyStr,
);

sub _build_help_pod {
    my $self = shift;
    my $file = $INC{ module_notional_filename($self->package) };

    my ($heading) = Pod::Abstract->load_file($file)->select('/head1[@heading =~ {^DESCRIPTION$}](0)');
    return undef unless $heading;

    # Remove =cut blocks so we don't return them.  They should be harmless to
    # most POD formatters, but it's aesthetically pleasing to remove them.
    $_->detach for $heading->select("//#cut");

    # Return the POD source of the heading's children, but not the heading
    # itself.  This avoids returning the =head1 element.
    return join "", "=pod\n\n", map { $_->pod } $heading->children;
}


=head2 fields

An ArrayRef of HashRefs, each representing a data field present in
L<Viroverse::Import/key_map>.  Currently the hashrefs have just C<name> and
C<required> keys.

Read-only.

=head2 options

An ArrayRef of HashRefs, each representing a per-job importer option (that is,
importer attributes).  Currently the hashrefs have just C<name> and C<required>
keys.

Read-only.

=cut

has [qw[ fields options ]] => (
    is  => 'lazy',
    isa => ArrayRef[
        Dict[
            name     => NonEmptySimpleStr,
            required => Bool,
        ]
    ],
);

sub _build_fields {
    my $self    = shift;
    my $package = $self->package;

    my $attr = $package->meta->find_attribute_by_name("key_map")
        or die "$package doesn't have a 'key_map' attribute‽";

    my $type = $attr->type_constraint
        or die "$package attribute 'key_map' is missing a type constraint‽";

    die "Type constraint of $package attribute 'key_map' isn't a Dict"
        unless $type->is_a_type_of(Dict);

    # Handle our WithOptionalFreezerLocation type, and Unions of Dicts in
    # general, by picking the first sub-type in the Union.
    #
    # For WithOptionalFreezerLocation, the first sub-type is the Dict which
    # marks the freezer location keys as optional empty strings.  (The second
    # marks the same keys as required, thus requiring either all of the keys or
    # none of them.)
    #
    # Other unions should similarly put their least restrictive type first.
    $type = $type->type_constraints->[0]
        if $type->isa("Type::Tiny::Union");

    die "Type constraint of $package attribute 'key_map' isn't parameterized"
        unless $type->is_parameterized;

    # We've ensured $type is a parameterized Dict, so we can fetch its named
    # parameters and inspect their types for optional-ness.
    return [
        pairmap {;
           +{
                name     => $a,
                required => $b->is_strictly_a_type_of(Optional) ? 0 : 1,
            }
        } @{ $type->parameters }
    ];
}

sub _build_options {
    my $self      = shift;
    my $package   = $self->package;
    my %from_role = map { $_ => 1 } Viroverse::Import->meta->get_attribute_list;

    # All attributes, except those which are:
    #   • private (start with an underscore)
    #   • from Viroverse::Import
    #   • have a default or a builder
    return [
        map {
           +{
               name     => $_->name,
               required => $_->is_required ? 1 : 0,
            }
        }
       sort { $a->name cmp $b->name }
       grep { not ($_->has_default or $_->has_builder) }
       grep { not $from_role{ $_->name } }
       grep { $_->name !~ /^_/ }
            $package->meta->get_all_attributes
    ];
}

sub BUILD {
    my ($self, $args) = @_;
    die "At least one of the package or name attributes must be provided"
        unless $args->{package} or $args->{name};
}

# Make instances of this class singletons for any given package.  Note that a
# new object is built every time so that we can use its "package" attribute as
# a cache key and avoid inspecting the arguments to "new".  Only the first
# object built for a package is ever returned though.
around 'new' => sub {
    my ($orig, $self) = @_;
    my $new  = $self->$orig(@_);

    state $singletons = {};
    return $singletons->{ $new->package } ||= $new;
};

=head1 STATIC METHODS

=head2 load_all

Loads all packages under the L<Viroverse::Import> namespace which are
L<Viroverse::Types/ImporterClass> and returns an array of
L<Viroverse::ImportType> instances, one for each loaded importer package.

The return value is only built once and used for every subsequent call.  This
avoids scanning the filesystem and building new instances of this class on
every call.

=cut

sub load_all {
    my $self = shift;

    state $types = [
        map { $self->new( package => $_ ) }
       sort { $a cmp $b }
       grep { ImporterClass->check($_) && $_->is_enabled }
            Module::Pluggable::Object->new(
                search_path      => "Viroverse::Import",
                require          => 1,
                on_require_error => sub {
                    confess "Couldn't require $_[0]: $_[1]";
                },
            )->plugins
    ];

    return @$types;
}

1;
