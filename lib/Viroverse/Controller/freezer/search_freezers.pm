package Viroverse::Controller::freezer::search_freezers;

use strict;
use warnings;
use base 'Viroverse::Controller::freezer';

sub addFoundToFreezer : Local {
    my ($self, $context) = @_;

    my @ids = @{$context->req->args()};
    my @can_add = ('aliquot');
    foreach my $id (@ids) {
        my $a = Viroverse::Model::aliquot->retrieve($id);
        if($a->is_missing){
            push @can_add, $id;
        }
    }
    if ($#can_add > 0){
        $context->forward('Viroverse::Controller::sidebar', 'add' , \@can_add);
        $context->response->{body} = 1;
    }
    else{
        $context->detach('Viroverse::Controller::ajax_error', 'make_error', ['All vials are already placed or otherwise accounted for']);
    }
    return;
}

sub aliquot_admin_summary_by_patient : Local {
# routine to provide results for find aliquots search (patient visit or assigned scientist)
    my ($self, $c) = @_;

    if (defined  $c->request->params->{patient_id} || defined  $c->request->params->{scientist}) {

        my %args;
        $args{patient_id} = $c->request->params->{patient_id} if defined $c->request->params->{patient_id};
        $args{scientist}  = $c->request->params->{scientist}  if defined $c->request->params->{scientist};
        $args{min_vials}  = $c->request->params->{min_vials}  if defined $c->request->params->{min_vials};
        $args{freezers}   = $c->stash->{freezers};
        if ($c->request->params->{tissues}) {
            $args{tissue_ids} = ref $c->request->params->{tissues} ?
                 $c->request->params->{tissues} :
                [$c->request->params->{tissues}];
        }
        if ( $c->request->params->{dates}) {
            $args{dates} = ref $c->request->params->{dates} ?
                 $c->request->params->{dates} :
                [$c->request->params->{dates}];
        }
        if ($c->request->params->{filters}) {
            $args{filters} = ref $c->request->params->{filters} ?
                 $c->request->params->{filters} :
                [$c->request->params->{filters}];
        }

        # get return value(s)
        my $results_ref = Viroverse::Model::aliquot->admin_summary_by_patient(\%args);

        # return results
        $c->stash->{jsonify} = $results_ref;
        $c->forward('Viroverse::View::JSON2');
    }
    else {
        $c->detach('Viroverse::Controller::ajax_error', 'make_error', ['No valid patient or possessing scientist supplied.  Please try again.']);
    }
    return;
}

sub aliquot_search : Local {
# provides list of cohorts the current user can access
    my ($self, $c) = @_;
    $c->forward('Viroverse::Controller::sidebar','sidebar_to_stash');
    $c->stash->{cohorts} = $c->model("ViroDB::Cohort")->list_all;
    $c->stash->{template} = 'aliquot-search.tt';
    $c->forward('Viroverse::View::TT');
    return;
}

sub aliquot_summary_by_box : Local {
# pull summary information by box name
    my ($self, $c) = @_;

    my $attempt = 0;
    $c->forward('Viroverse::Controller::sidebar','sidebar_to_stash');

    if (defined  $c->request->params->{pattern}) {

        my %args;
        $args{box_pattern} = $c->request->params->{pattern};
        $args{min_vials}   = $c->request->params->{min_vials} if defined $c->request->params->{min_vials};
        $args{freezers}    = $c->stash->{freezers};
        $c->stash->{box_pattern} = $args{box_pattern};

        # modify pattern for SQL
        $args{box_pattern} =~ s/([%_])/\\$1/;
        $args{box_pattern} =~ s/\*/\%/g;
        $args{box_pattern} =~ s/\?/_/g;

        # get return value(s)
        $c->stash->{boxes} = Viroverse::Model::aliquot->summary_by_box(\%args);
        $attempt++;
    }

    if (defined $c->stash->{boxes} && @{$c->stash->{boxes}}) {
        $c->stash->{template} = 'box-search.tt';
    } else {
        $c->stash->{error}    = 'No boxes found.  Please try again.' if $attempt;
        $c->stash->{template} = 'box-sel.tt';
    }
    return;
}

sub aliquot_summary_selection : Local {
# supplies visit dates and tissues types to find aliquots/patient visit page when patient id/alias, min aliquot count or tissue type is selected.
    my ($self, $c) = @_;

    # check for passed arguments and attempt to instantiate patient (POST only for now)
    if (defined $c->req->params->{patient_id}) {

        my %args;
        $args{patient_id} = $c->request->params->{patient_id} if defined $c->request->params->{patient_id};
        $args{min_vials}  = $c->request->params->{min_vials}  if defined $c->request->params->{min_vials};
        $args{freezers}   = $c->stash->{freezers};
        if ($c->request->params->{tissues}) {
            $args{tissue_ids} = ref $c->request->params->{tissues} ?
                 $c->request->params->{tissues} :
                [$c->request->params->{tissues}];
        }
        if ($c->request->params->{filters}) {
            $args{filters} = ref $c->request->params->{filters} ?
                 $c->request->params->{filters} :
                [$c->request->params->{filters}];
        }

        # get return value(s)
        my $results_ref = Viroverse::Model::aliquot->summary_selection(\%args);
        $c->stash->{'jsonify'}->{visits}  = $results_ref->{visits}  if exists $results_ref->{visits};
        $c->stash->{'jsonify'}->{tissues} = $results_ref->{tissues} if exists $results_ref->{tissues};
        $c->forward('Viroverse::View::JSON2');
    }
    else {
        $c->detach('Viroverse::Controller::ajax_error', 'make_error', ['Patient not found.  Please try again.']);
    }
    return;
}

1;
