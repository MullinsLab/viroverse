use strict;
use warnings;
use utf8;
use 5.018;

package Viroverse::Import::ProjectMaterials;
use Moo;
use Types::Common::String qw< SimpleStr NonEmptySimpleStr >;
use Types::Standard -types;
use ViroDB;
use Viroverse::CachingFinder;
use Viroverse::Logger qw< :log :dlog >;
use namespace::clean;

with 'Viroverse::Import',
     'Viroverse::Import::CanFindPatientSample';

=head1 DESCRIPTION

=encoding UTF-8

This importer adds samples to projects and optionally assigns a scientist to
each sample.  All projects, samples, and scientists must already exist.
Scientists are looked up by full name. (Not username.)

If a sample is already in the given project, the assigned scientist is
re-assigned or removed as necessary.

A mapped but empty scientist field will unassign any scientist from an existing
project sample.

If you just want to add samples to a project without touching any possible
existing assignments, don’t map a scientist data column.

=cut

__PACKAGE__->metadata->set_label("Project Materials");
__PACKAGE__->metadata->set_primary_noun("sample");

has _cohorts => (
    is      => 'ro',
    isa     => InstanceOf["Viroverse::CachingFinder"],
    default => sub {
        Viroverse::CachingFinder->new(
            resultset => ViroDB->instance->resultset("Cohort"),
            field     => "name",
        )
    },
);

has _scientists => (
    is      => 'ro',
    isa     => InstanceOf["Viroverse::CachingFinder"],
    default => sub {
        Viroverse::CachingFinder->new(
            resultset => ViroDB->instance->resultset("Scientist"),
            field     => "name",
        )
    },
);

has _projects => (
    is      => 'ro',
    isa     => InstanceOf["Viroverse::CachingFinder"],
    default => sub {
        Viroverse::CachingFinder->new(
            resultset => ViroDB->instance->resultset("Project"),
            field     => "name",
        )
    },
);

has '+key_map' => (
    isa => Dict[
        # For the sample
        cohort              => NonEmptySimpleStr,
        external_patient_id => NonEmptySimpleStr,
        sample_date         => NonEmptySimpleStr,
        sample_name         => Optional[SimpleStr],
        tissue_type         => NonEmptySimpleStr,
        additive            => Optional[SimpleStr],

        # For the project
        project             => NonEmptySimpleStr,

        # For the optional assigned scientist
        scientist           => Optional[SimpleStr],
    ],
);

sub suggested_column_for_key_pattern {
    my ($package, $key) = @_;
    return {
        external_patient_id => qr/patient|subject|participant/i,
        sample_date         => qr/date/i,
        sample_name         => qr/sample_name|sample/i,
        tissue_type         => qr/tissue|material(?! modifier)/i,
        additive            => qr/additive|modifier/i,
        scientist           => qr/scientist/i,
    }->{$key};
}

sub process_row {
    my ($self, $row) = @_;
    state $db = ViroDB->instance;

    # If there's no scientist mapped for the row, then there was no scientist
    # data column and we just want to ignore scientist for the assigned sample.
    # Determine this early so we don't have to worry about autovivifying the
    # key to undef (which would mean removing an assigned scientist).
    my $ignore_scientist = not exists $row->{scientist};

    my $project   = $self->_projects->find( $row->{project} );
    my $scientist = $row->{scientist}
        ? $self->_scientists->find( $row->{scientist} )
        : undef;

    my $cohort = $self->_cohorts->find( $row->{cohort} );

    my ($patient, $sample) = $self->find_patient_sample(
        $cohort,
        $row->{external_patient_id},
        {
            date        => $row->{sample_date},
            name        => $row->{sample_name},
            tissue_type => $row->{tissue_type},
            additive    => $row->{additive},
        }
    );

    my $sample_description =
        sprintf "%s sample for %s %s on %s%s (#%s)",
            $row->{tissue_type},
            $cohort->name,
            $row->{external_patient_id},
            $row->{sample_date},
            ($row->{sample_name} ? " named “$row->{sample_name}”" : ""),
            $sample->id;

    # Look for existing assignment.  If found, update scientist (assign or
    # unassign).  If not found, create.  This is very similar to
    # Project->assign, but lets us more tightly track what we do.
    my $assignment = $project->sample_assignments->find({ sample_id => $sample->id });

    if ($assignment) {
        if ($ignore_scientist) {
            log_debug {[ "Sample %s already in project", $sample->id ]};
            $self->track("Sample already in project");
        } else {
            if ($scientist) {
                if ($assignment->assigned_scientist and $assignment->assigned_scientist->id == $scientist->id) {
                    log_debug {[ "Sample %s scientist assignment unchanged", $sample->id ]};
                    $self->track("Assignment unchanged");
                } else {
                    log_info {[
                        "Scientist for %s set to %s (#%s)",
                        $sample_description,
                        $scientist->name,
                        $scientist->id
                    ]};

                    $self->track(
                        $assignment->desig_scientist_id
                            ? "Scientist re-assigned"
                            : "Scientist assigned"
                    );

                    $assignment->assigned_scientist( $scientist );
                    $assignment->update;
                }
            } else {
                if ($assignment->assigned_scientist) {
                    log_info { "Scientist unassigned from $sample_description" };
                    $self->track("Scientist unassigned");
                    $assignment->assigned_scientist( undef );
                    $assignment->update;
                } else {
                    log_debug {[ "Sample %s already in project and unassigned", $sample->id ]};
                    $self->track("Assignment unchanged");
                }
            }
        }
    } else {
        log_info {[ "Added %s to project %s", $sample_description, $project->name ]};
        $self->track("Sample added to project");
        $project->sample_assignments->create({
            sample => $sample,
            ($scientist
                ? (assigned_scientist => $scientist)
                : ()),
        });
    }
}

1;
