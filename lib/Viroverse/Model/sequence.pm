use strict;
use warnings;
use 5.010;

package Viroverse::Model::sequence;
use base 'Viroverse::CDBI';
use Sort::ByExample;

=encoding UTF-8

=head1 NAME

Viroverse::Model::sequence - Base class for all sequences

=head1 DESCRIPTION

This sequence base class provides common methods for all types of sequences.
Currently Viroverse only supports L<DNA and RNA sequences|Viroverse::Model::sequence::dna>
(despite the class name suggesting only DNA), but it might support protein
sequences in the future.

You shouldn't use this class directly.

=head1 METHODS

=head2 get_FASTA

A string is returned in the FASTA format for the object's sequence.  Bases are
uppercased and wrapped at 50 characters.

Passes all parameters to L</fasta_description>.

=cut

sub get_FASTA {
    my $self = shift;

    my $return   = '>' . $self->fasta_description(@_) . "\n";
    my $sequence = $self->seq();
    $sequence =~ s/(.{50})/$1\n/g; #print 50 nucleotides|bases per line
    $return .= uc($sequence)."\n";

    return $return;
}

=head2 fasta_description

By default returns a string of the following L</name_parts> joined with pipes
(C<|>):

=over

=item * Viroverse accession number (id.rev)

=item * name given by scientist

=item * scientist's full name

=back

Optionally takes the following key-value pairs:

=over

=item name

An arrayref of name parts to use for the FASTA description line.  Values should
be strings which correspond to keys in L</name_parts> or scalar refs which are
treated as static slugs in the name.  The latter is useful for constant
prefixes or suffixes.

=item sep

The string with which to join together each name part.

=item filter

A coderef through which all name part values are passed before being joined.
This may be useful for replacing/removing restricted characters in certain
environments.  For example:

    filter => sub { s/[,;\s]/_/gr }

would replace all commas, semi-colons, and spaces with underscores.  The topic,
C<$_>, is set to the current value, which is also passed as the first ag.  The
return value of the coderef is used as the new value.

=back

The default behaviour is equivalent to:

    $seq->fasta_description(
        name => [qw[ idrev name scientist ]],
        sep  => '|',
    );

=cut

sub fasta_description {
    my $self = shift;
    my %args = (
        sep => '|',
        @_
    );
    $args{name} = [qw[ idrev name scientist ]]
        if not defined $args{name}
        or (ref $args{name} and not @{ $args{name} });

    my $parts = $self->name_parts;
    my @name =
        map { $_->{value}->($self) // "" }
       grep { ref($_) eq 'HASH' }
        map {
            my $part = $_;
            ref($part)
                ? { value => sub { $$part } }
                : $self->name_parts->{$part}
        } @{ $args{name} };

    @name = map { $args{filter}->($_) } @name
        if $args{filter};

    return join $args{sep}, @name;
}

=head2 name_parts

Returns a hashref representing the parts that a sequence name be constructed
out of.  Keys are the internal part names, values are hashrefs that contain the
following keys:

=over

=item * label

The friendly name of the part.

=item * value

A coderef which expects to be called as a method on a sequence object and
returns a string.

=back

May be called as a class method.

The current keys are:

=over

=item * amplicon

=item * cds

=item * date

=item * genbank_acc

=item * id

=item * idrev

=item * name

=item * patient

=item * pcr_nickname

=item * scientist

=item * tissue

=item * tissue_abbr

=back

=cut

sub name_parts {
    return {
        name => {
            label => 'Name',
            value => sub { shift->name },
        },
        patient => {
            label => 'Patient',
            value => sub {
                my $self = shift;
                return "" unless defined $self->sample_id;
                return "" unless defined $self->sample_id->patient;
                return $self->sample_id->patient->name;
            },
        },
        scientist => {
            label => 'Scientist',
            value => sub { shift->scientist },
        },
        id => {
            label => 'Viroverse Accession number',
            value => sub { shift->na_sequence_id },
        },
        idrev => {
            label => 'Viroverse Accession number + revision',
            value => sub { shift->idrev },
        },
        genbank_acc => {
            label => 'GenBank Accession number',
            value => sub { shift->genbank_acc },
        },
        pcr_nickname => {
            label => 'PCR nickname',
            value => sub {
                my $pcr = shift->pcr_product_id
                    or return "";
                return $pcr->name // "";
            },
        },
        cds => {
            label => 'CDS overlaps',
            value => sub {
                my $cds = shift->hxb2_cds
                    or return;
                return join "-", @{$cds->{overlaps}};
            },
        },
        amplicon => {
            label => 'Amplicon (Autopsy-only for now)',
            value => sub { shift->amplicon },
        },
        tissue => {
            label => 'Tissue name',
            value => sub {
                my $self = shift;
                return "" unless $self->sample_id;
                return "" unless $self->sample_id->tissue_type;
                return $self->sample_id->tissue_type->name;
            },
        },
        tissue_abbr => {
            label => 'Tissue/molecule abbreviation',
            value => sub { shift->tissue_molecule_abbreviation },
        },
        date => {
            label => 'Sample date',
            value => sub {
                my $self = shift;
                return "" unless $self->sample_id;
                return "" unless $self->sample_id->date;
                return $self->sample_id->date->strftime("%Y-%m-%d");
            },
        },
    }
}

=head2 name_parts_sorted

Returns an arrayref of hashrefs, one for each part in L</name_parts>, sorted by
name.  As the lone exception, C<id> and C<idrev> are always first.

The hashrefs omit the C<value> key and contain an additional key, C<name>,
which is the key from L</name_parts>.

=cut

sub name_parts_sorted {
    my $self  = shift;
    my $parts = $self->name_parts;

    state $sorter = Sort::ByExample->sorter(
        [qw[ id idrev ]],
        sub { $_[0] cmp $_[1] }
    );

    return [
         map { delete $_->{value}; $_ }
         map {; +{ name => $_, %{ $parts->{$_} } } }
             $sorter->(keys %$parts)
    ];
}

=head2 scientist

Returns the full name of the L<Viroverse::Model::scientist> associated with
this sequence, or the empty string if there's no scientist.

=cut

sub scientist {
     my $self = shift;
     if($self->scientist_id()){
          return $self->scientist_id->name();
     }
     return "";
}

1;
