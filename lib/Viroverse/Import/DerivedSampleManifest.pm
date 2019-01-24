use strict;
use warnings;
use utf8;
use 5.018;

package Viroverse::Import::DerivedSampleManifest;
use Moo;
use Viroverse::Logger qw< :log :dlog >;
use Types::Standard -types;
use Viroverse::Types -types;
use Types::Common::String qw< SimpleStr NonEmptySimpleStr >;
use ViroDB;
use namespace::clean;

with 'Viroverse::Import',
     'Viroverse::Import::HasCreatingScientist',
     'Viroverse::Import::CanPlaceAliquot',
     'Viroverse::Import::CanPrepareSample';

=head1 DESCRIPTION

Loads the details of samples derived from an existing sample, adding samples
and aliquots. This importer is B<not idempotent>: if you run it repeatedly with
the same file as input, it will create new aliquots each time. It will not
create any derivations or duplicate samples.

=cut

has unit => (
    is => 'ro',
    isa => ViroDBRecord["Unit"],
    coerce => 1,
    required => 1,
);


has '+key_map' => (
    isa => WithOptionalFreezerLocation[
        derivation_id             => NonEmptySimpleStr,
        tissue_type               => NonEmptySimpleStr,
        sample_date               => Optional[SimpleStr],
        sample_name               => Optional[SimpleStr],
        additive                  => Optional[SimpleStr],
        amount                    => NonEmptySimpleStr,
    ],
);

sub suggested_column_for_key_pattern {
    my ($package, $key) = @_;
    return {
        sample_date         => qr/date/i,
        additive            => qr/additive|modifier/i,
        tissue_type         => qr/tissue|material(?! modifier)/i,
        amount              => qr/amount|vol/i
    }->{$key};
}


sub process_row {
    my ($self, $row) = @_;
    state $db = ViroDB->instance;

=over

=item *

The derivation is looked up by derivation ID. If no derivation is found,
processing fails.

=cut

    my $derivation = $db->resultset("Derivation")->find($row->{derivation_id})
        or die "No matching derivation found";

=item *

The derivation is checked for an existing sample of the given tissue type,
name, date, and additive. If no sample is found, one is created. If more than
one sample is found, processing fails.

=cut
    my $sample = $self->find_or_build_sample(
        $derivation->related_resultset("output_samples"),
        {
            name           => $row->{sample_name} || undef,
            tissue_type    => $row->{tissue_type},
            additive       => $row->{additive}    || undef,
            date_collected => $row->{sample_date} || undef,
        }
    );

    if (!$sample->in_storage) {
        $sample->insert;
        $self->track("Sample created");
        log_debug {[ "Created a(n) %s sample" , $row->{tissue_type} ]};
    }

=item *

An aliquot of the sample with the given amount is created.
=cut
    my $aliquot = $sample->add_to_aliquots({
        vol                => $row->{amount},
        unit               => $self->unit,
        creating_scientist => $self->creating_scientist,
    });
    $self->track("Aliquot created");

=item *

If the aliquot has a freezer, rack, and box set, the aliquot is
placed into the next empty position in the indicated box.

=back

=cut

    $self->place_aliquot($row, $aliquot);


    log_info { ["Aliquot created for %s %s %s “%s”: %f %s",
                $derivation->protocol->name,
                $sample->tissue_type->name,
                $sample->date->strftime("%Y-%m-%d"),
                $sample->name,
                $aliquot->vol,
                $aliquot->unit->name,
               ]};

}

1;
