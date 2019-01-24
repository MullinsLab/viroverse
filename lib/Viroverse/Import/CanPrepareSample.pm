use strict;
use warnings;
use utf8;
use 5.018;

package Viroverse::Import::CanPrepareSample;
use Moo::Role;
use Viroverse::Logger qw< :log >;
use Types::Standard -types;
use Type::Params qw< compile Invocant >;
use namespace::clean;

=head1 METHODS

=head2 find_or_build_sample

Given a L<sample resultset|ViroDB::ResultSet::Sample> and a hashref of fields,
retrieve a single sample record matching the query fields. If none exists, build
a sample instance and return it without storing it.

Supported fields:

=over

=item C<tissue_type> (required)

=item C<additive>

=item C<name> (sample name)

=item C<date_collected>

=back

=cut

sub find_or_build_sample {
    my $self = shift;
    state $params = compile( InstanceOf["ViroDB::ResultSet::Sample"],
                             Dict[
                                 tissue_type => Str,
                                 name => Optional[Maybe[Str]],
                                 additive => Optional[Maybe[Str]],
                                 date_collected => Optional[Maybe[Str]]
                             ]);
    my ($resultset, $opts) = $params->(@_);

    my $db = $resultset->result_source->schema;

    my $found = $resultset->find_naturally({
        tissue_type    => $opts->{tissue_type},
        name           => $opts->{name} || undef,
        additive       => $opts->{additive} || undef,
        date_collected => $opts->{date_collected} || undef,
    });

    return $found if $found;

    my $tissue_type = $db->resultset("TissueType")->find({ name => { 'ilike' => $opts->{tissue_type} } })
        or die "Unknown tissue type: " . $opts->{tissue_type};

    my $additive;
    if ($opts->{additive}) {
        $additive = $db->resultset("Additive")->find({ name => $opts->{additive} })
            or die "Unknown additive: " . $opts->{additive};
    }

    return $resultset->new({
        tissue_type => $tissue_type,
        ($additive               ? (additive => $additive)                     : ()),
        ($opts->{name}           ? (name => $opts->{name})                     : ()),
        ($opts->{date_collected} ? (date_collected => $opts->{date_collected}) : ()),
    });
}

1;
