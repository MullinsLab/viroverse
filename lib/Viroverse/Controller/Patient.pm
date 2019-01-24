use strict;
use warnings;
use utf8;
use 5.018;

package Viroverse::Controller::Patient;
use Moose;
use Catalyst::ResponseHelpers qw< :helpers :status >;
use List::MoreUtils qw< uniq >;
use Viroverse::patient;
use namespace::clean;

# Since these are used in action signatures, they must come after namespace::clean
# so they remain in the package for the dispatcher to find at runtime.
use Types::Common::Numeric qw< PositiveInt >;
use Types::Common::String qw< NonEmptySimpleStr >;

BEGIN { extends 'Viroverse::Controller' }

sub redirect : Path('/summary/patient') Args {
    my ($self, $c, @args) = @_;
    return RedirectToUrl($c, $c->uri_for("/subject", @args), HTTP_MOVED_PERMANENTLY);
}

sub base : Chained('/') PathPart('subject') CaptureArgs(0) { }

sub select : Chained('base') PathPart('') Args(0) {
    my ($self, $c) = @_;
    $c->stash(
        cohorts  => $c->model("ViroDB::Cohort")->list_all,
        template => 'patient-sel.tt'
    );
}

sub load_from_params : POST Chained('base') PathPart('') Args(0) {
    my ($self, $c) = @_;
    my $params = $c->request->params;
    my $patient;

    if ($params->{cohort_id} and ($params->{patient} or $params->{ext_pat_id})) {
        my $id = $params->{patient} || $params->{ext_pat_id};
        $patient = Viroverse::patient::get( $c->stash->{session}, $id, { cohort_id => $params->{cohort_id} } );
    }

    my ($action, @params);
    if ($patient) {
        # Canonicalize URLs to /subject/:id for easier bookmarking,
        # copy and paste, etc.
        ($action, @params) = ( show_by_id => [ $patient->give_id ] );
    } else {
        ($action, @params) = (
            select => {
                mid => $c->set_error_msg("Patient not found.  Please try again.")
            }
        );
    }
    $c->res->redirect( $c->uri_for_action( $self->action_for($action), @params ) );
}

sub load_by_id : Chained('base') PathPart('') CaptureArgs(PositiveInt) {
    my ($self, $c, $id) = @_;
    my $patient = Viroverse::patient::get($c->stash->{session}, $id)
        or return NotFound($c, "Patient #$id not found");
    $c->stash( current_model_instance => $patient );
}

sub load_by_cohort_and_id : Chained('base') PathPart('') CaptureArgs(NonEmptySimpleStr, NonEmptySimpleStr) {
    my ($self, $c, $cohort, $id) = @_;
    my $patient = Viroverse::patient::get($c->stash->{session}, $id, { 'cohort.name' => $cohort })
        or return NotFound($c, "Patient «$cohort $id» not found");
    $c->stash( current_model_instance => $patient );
}

sub show_by_id            : Chained('load_by_id')            PathPart('') Args(0) { shift->show(@_) }
sub show_by_cohort_and_id : Chained('load_by_cohort_and_id') PathPart('') Args(0) { shift->show(@_) }
sub show_tab_by_id        : Chained('load_by_id')            PathPart('tab') Args(1) { shift->show(@_) }
sub show_tab_by_cohort_and_id : Chained('load_by_cohort_and_id') PathPart('tab') Args(1) { shift->show(@_) }
sub show {
    my ($self, $c, $tab) = @_;
    my $patient = $c->stash->{patient} = $c->model;
    my $virodb_patient = $c->model("ViroDB::Patient")->find($patient->give_id);
    $c->stash->{virodb_patient} = $virodb_patient;

    $c->stash->{patient_names} = [
         map { join " ", ($_->cohort->name, $_->external_patient_id) }
            $virodb_patient->primary_aliases
    ];
    $c->stash->{patient_pub_ids} = [
         map { join " ", ($_->cohort->name, $_->external_patient_id, "(pub id)") }
            $virodb_patient->publication_aliases
    ];
    $c->stash->{patient_aliases} = [
         map { join " ", ($_->cohort->name, $_->external_patient_id, "(alias)") }
            $virodb_patient->other_aliases
    ];

    $c->stash->{cohorts}  = $c->model("ViroDB::Cohort")->list_all;
    $c->forward('Viroverse::Controller::sidebar','sidebar_to_stash');

    if (! defined $tab) {
        $c->stash->{template} = 'sum-patient.tt';
    } elsif ($tab eq "samples") {
        $c->stash->{template} = 'sum-patient-samples.tt'
    } elsif ($tab eq "labs") {

        # Fetch all numeric lab results for this patient except VLs and CD4/CD8
        # cell counts, which we get normalized elsewhere.
        my $labs = $c->model("ViroDB::NumericLabResult")
            ->search({}, { join => ['visit', { type => 'unit' }] })
            ->search({ 'visit.patient_id' => $c->model->give_id })
            ->without_viral_load_and_cell_counts
            ->order_by("type.name", "visit.visit_date")
            ->add_columns([
                { assay      => 'type.name' },
                { unit       => 'unit.name' },
                { visit_date => 'visit.visit_date' },
            ]);

        my $vls = $virodb_patient->viral_loads;

        my $cells = $virodb_patient
            ->cell_counts
            ->add_columns([
                { assay => 'cell_type' }
            ]);

        $c->stash(
            template => 'sum-patient-labs.tt',
            labs     => [
                $labs->all,
                $cells->all,
                (map { +{ %$_,
                          assay => 'Viral load',
                          value => $_->{viral_load} || $_->{limit_of_quantification} } }
                 map { $_->as_hash }
                     $vls->all),
            ],
        );
    } elsif ($tab eq "sequences") {
        $c->stash->{template} = 'sum-patient-sequences.tt';
    } elsif ($tab eq "epitopes") {

        unless ($c->stash->{features}->{epitopedb}) {
            return NotFound($c, "Feature disabled: EpitopeDB");
        }

        ##TODO: make below not necessary, or move into epitope_db
        $c->req->param('patient', $patient->give_id() );
        $c->req->param('hla', 0);
        $c->req->param('pept_gene', 1);
        $c->req->param('lengtha', '-- None --');
        $c->req->param('lengthb', '-- None --');
        $c->req->param('pept_name', '-- None --');
        $c->req->param('pept_seq', '-- None --');
        $c->forward('Viroverse::Controller::search::epitopedb_search::peptide','result');
        $c->stash->{template} = 'sum-patient-epitopes.tt';
    } else {
        return Redirect($c, $self->action_for('show_by_id'), [ $c->model->give_id ] );
    }
}

sub chart_spec : Chained('load_by_id') PathPart('chart-spec.json') Args(0) {
    my ($self, $c) = @_;

    my $patient = $c->model("ViroDB::Patient")->find($c->model->give_id);

    my $meds    = $patient->patient_medications->prefetch({ medication => "arv_class" });

    # XXX TODO: More of this business logic, especially the is_deleted stuff,
    # should get pushed into the resultset classes.
    # -trs, 24 May 2016
    my $samples = $patient->visits->search(
        {
            'tissue_type.name'  => { -in => ['plasma', 'PBMC', 'Leukapheresed cells'] },
            -and                => [
                -not_bool => 'me.is_deleted',
            ],
        },
        {
            join     => { samples => 'tissue_type' },
            columns  => [
                'visit_date',
                { tissue       => 'tissue_type.name' },
                { sample_count => { count => 'samples.sample_id' } },
            ],
            group_by => [qw[ visit_date tissue_type.name ]],
            order_by => [qw[ visit_date tissue_type.name ]],
        }
    );

    my $vega = $c->view('Vega');
    $vega->specfile('patient-chart.json');
    $vega->bind_data({
        "patient"     => [{
            id   => $patient->id,
            name => $patient->name,
            publication_name => $patient->publication_name,
        }],
        "viral-loads" => [ $patient->viral_loads ],
        "cell-counts" => [ $patient->cell_counts ],
        "infection"   => [ $patient->infections ],
        "samples"     => [ $samples->all ],
        "medications" => [ $meds->all ],
        "arv-classes" => [
            $c->model("ViroDB::ArvClass")->all,
            $c->model("ViroDB::Medication")->new_unknown->arv_class,
        ],
    });
    $c->detach($vega);
}

1;
