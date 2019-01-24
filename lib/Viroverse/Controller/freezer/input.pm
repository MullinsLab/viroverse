package Viroverse::Controller::freezer::input;

use strict;
use warnings;
use base 'Viroverse::Controller';
use Catalyst::ResponseHelpers;
use List::MoreUtils qw[firstidx];
use Carp;
use namespace::autoclean;

sub section { 'freezer' }

sub base : ChainedParent PathPart('input') CaptureArgs(0) { }

sub protected : Chained('base') PathPart('') CaptureArgs(0) {
    my ($self, $c) = @_;
    return Forbidden($c, "You are not allowed to make modifications to freezers.")
        unless $c->stash->{scientist}->can_manage_freezers;
}

sub add_samples : Chained('protected') PathPart('add_samples') Args {
    my ($self, $c) = @_;

    my @units = $c->model("ViroDB::Unit")->order_by(\[ 'lower(name)' ])->all;
    my @unit_hash = map { { unit_id => $_->unit_id, name => $_->name } } @units;

    my @additives = $c->model("ViroDB::Additive")->order_by(\[ 'lower(name)' ])->all;
    my @additive_hash = map { { additive_id => $_->additive_id, name => $_->name} } @additives;

    my @commonSamples = $c->model("ViroDB::TissueType")->search({ name => [ 'serum', 'plasma', 'PBMC', 'semen, supernatant', 'semen, pellet', 'cervix', 'Leukapheresed cells' ]}, {order_by => \[ 'lower(name)' ]});

    my @commonTissueEnum;
    foreach (@commonSamples){
        if($_->name eq 'plasma'){
            push(@commonTissueEnum, {id => $_->tissue_type_id, name => "Plasma, Large" });
            push(@commonTissueEnum, {id => $_->tissue_type_id, name => "Plasma, Small" });
            push(@commonTissueEnum, {id => $_->tissue_type_id, name => "Plasma, Thawed" });
        }else{
            push(@commonTissueEnum, {id => $_->tissue_type_id, name => ucfirst($_->name) });
        }
    }
    my @allTissue = $c->model("ViroDB::TissueType")->order_by(\[ 'lower(name)' ])->all;
    my @tissueEnum = map {{id => $_->tissue_type_id, name => ucfirst($_->name) }} @allTissue;

    $c->stash->{Tissues} = Viroverse::View::JSON2->encode_json($c, {jsonify => {tissues =>{common => \@commonTissueEnum, all => \@tissueEnum}, units => \@unit_hash, additives => \@additive_hash}});
    $c->stash->{units} = \@units;
    $c->stash->{additives} = \@additives;
    $c->stash->{commonTissues} = \@commonTissueEnum;
    $c->stash->{selected_cohort} = 1;
    $c->stash->{template} = 'new_aliquots.tt';
    $c->forward('Viroverse::View::TT');
    return;
}

sub manageFreezers : Chained('base') PathPart('manageFreezers') Args {
    my ($self, $c) = @_;
    return Redirect($c, "/freezer/summary/index");
}

sub updateFreezer : Chained('protected') PathPart('updateFreezer') Args {
    my ($self, $c) = @_;

    # store request parameters for update/insert
    my $params =
        {name                  => $c->req->params->{freezer_name},
         creating_scientist_id => $c->stash->{scientist}->scientist_id,
         description           => $c->req->params->{freezer_description},
         location              => $c->req->params->{freezer_loc},
         upright_chest         => $c->req->params->{upright_chest},
         cane_alpha_int        => $c->req->params->{cane_label}
        };
    my $freezer_id       = $c->req->params->{freezer_id};

    # Validate user input - return error message via Ajax if invalid data is found
    # TODO: might move validation criterea to central location, add client-side validation
    my $err_msg;
    if (!defined $freezer_id || $freezer_id !~ /new || ^\d+$/i) {
        $err_msg = 'Invalid freezer selection';
    }
    elsif (!defined $params->{name} || $params->{name} !~ /\w/) {
        $err_msg = 'Invalid freezer name';
    }
    elsif (length($params->{name}) > 255) {
        $err_msg = 'Freezer name must be 255 characters or less';
    }
    elsif ($params->{name} =~ /^new$/i) {
        $err_msg = "Freezer cannot be named '$params->{name}'";
    }
    elsif (!defined $params->{location} || $params->{location} !~ /\w/) {
        $err_msg = 'Invalid freezer location';
    }
    elsif (!defined $params->{upright_chest} || $params->{upright_chest} !~ /^[cu]$/i) {
        $err_msg = 'Freezer type not selected';
    }
    $c->detach('Viroverse::Controller::ajax_error', 'make_error', [$err_msg]) if $err_msg;

    # create/update freezer using passed values
    my $freezer;

    # new freezer
    if (lc $freezer_id eq "new") {

        # get out if name is already in use
        $c->detach('Viroverse::Controller::ajax_error', 'make_error', ["Freezer name '$params->{name}' is already in use"])
            if $c->model("ViroDB::Freezer")->search({ name => $params->{name} })->count;

        # create freezer
        $freezer = $c->model("ViroDB::Freezer")->create($params);
        $freezer->discard_changes;
    }

    # existing freezer
    else {
        $freezer = $c->model("ViroDB::Freezer")->find($freezer_id);

        # get out if name has changed and new name is already in use
        if ($freezer->name ne $params->{name}) {
            $c->detach('Viroverse::Controller::ajax_error', 'make_error', ["Freezer name '$params->{name}' is already in use"])
                if $c->model("ViroDB::Freezer")->search({ name => $params->{name} })->count;
        }

        # update freezer
        $freezer->update($params);
    }
    $c->stash->{jsonify} = {freezer_id => $freezer->freezer_id, name => $freezer->name};
    $c->forward("Viroverse::View::JSON2");
    return;
}

sub addRacks : Chained('protected') PathPart('addRacks') Args {
    my ($self, $c) = @_;

    my $freezer = $c->model("ViroDB::Freezer")->find($c->req->params->{freezer_id});
    my $rack_count = $freezer->racks->count;
    my $next_name = $rack_count + 1;

    my $next_order;
    if ($rack_count) {
        $next_order = $freezer->racks->search(
            {},
            { order_by => { -desc => 'order_key' }}
        )->first->order_key + 1;
    } else {
        $next_order = 0;
    }

    for(my $i = 0 ; $i < $c->req->params->{num_racks} ; $i++){
        my $rack_name;
        if ($next_name < 26 && $c->req->params->{rack_alpha}) {
            $rack_name = chr($next_name + 64);
        } else {
            $rack_name = $next_name;
        }

        $freezer->add_to_racks({
            name                  => $rack_name,
            order_key             => $next_order,
            creating_scientist_id => $c->stash->{scientist}->scientist_id,
            num_rows              => $c->req->params->{rack_row},
            num_columns           => $c->req->params->{rack_col},
        });
        $next_name++;
        $next_order++;
    }

    $c->response->{body} = 1;
    return;
}

sub addBoxes : Chained('protected') PathPart('addBoxes') Args {
    my ($self, $c) = @_;

    my $rack = $c->model("ViroDB::Rack")->find($c->req->params->{rack_id});
    my $open_slots = ($rack->num_rows() * $rack->num_columns()) - $rack->boxes()->count;
    my $num_boxes = $c->req->params->{num_boxes};

    if($num_boxes > $open_slots){
        my $error_msg = $rack->location() . " Can Only Hold $open_slots More Boxes";
        $c->detach('Viroverse::Controller::ajax_error', 'make_error', [$error_msg]);
    }
    my $iter = $c->req->params->{name_start};
    for(my $i = 0 ; $i < $num_boxes ; $i++){
        my $name;
        my $order = $rack->freezer->upright_chest() eq 'c' ? $num_boxes - $i : $i; #boxes go in from bottom up in chest freezers
        if($iter > 0 && $c->req->params->{name_prefix} ne ""){
            $name = $c->req->params->{name_prefix} . " " . $iter;
        }else{
            $name = $c->req->params->{name_prefix} . $iter;
        }
        my $check_name = $rack->search_related('boxes', { name => $name });
        if($check_name->count > 0){
            my $error_msg = "A Box Named $name Already Exists in " . $rack->location . " !";
            $c->detach('Viroverse::Controller::ajax_error', 'make_error', [$error_msg]);
        }
        my $new_box = $rack->boxes->create_with_box_positions({
            name                  => $name,
            creating_scientist_id => $c->stash->{scientist}->scientist_id,
            num_rows              => $c->req->params->{num_rows},
            num_columns           => $c->req->params->{num_columns},
            order_key             => $order
        });
        $iter++;
    }

    $c->response->{body} = 1;
    return;
}

sub reorderBoxes : Chained('protected') PathPart('reorderBoxes') Args {
    my ($self, $c) = @_;

    my @boxes = @{$c->req->args};
    my $i = 0;
    my $txn = $c->model("ViroDB")->schema->txn_scope_guard;
    foreach my $box_id (@boxes) {
        my $box = $c->model("ViroDB::Box")->find($box_id);
        $box->update({ order_key => $i });
        $i++;
    }
    $txn->commit;

    $c->{response}->{body} = 1;
    return;
}

sub reorderRacks : Chained('protected') PathPart('reorderRacks') Args {
    my ($self, $c) = @_;

    my @racks = @{$c->req->args};
    my $i = 0;
    my $txn = $c->model("ViroDB")->schema->txn_scope_guard;
    foreach my $rack_id (@racks) {
        my $rack = $c->model("ViroDB::Rack")->find($rack_id);
        $rack->update({ order_key => $i });
        $i++;
    }
    $txn->commit;

    $c->{response}->{body} = 1;
    return;
}

sub editRack : Chained('protected') PathPart('editRack') Args {
    my ($self, $c) = @_;

    my $rows = $c->req->params->{num_rows};
    my $cols = $c->req->params->{num_cols};
    if($cols !~ /^\d{1,}$/  || $rows !~ /^\d{1,}$/){
        my $error_msg = "Rows and Collumns must be whole numbers either $rows or $cols is invalid";
        $c->detach('Viroverse::Controller::ajax_error', 'make_error', [$error_msg]);
    }
    my $rack = $c->model("ViroDB::Rack")->find($c->req->params->{rack_id});
    $rack->update({
        name        => $c->req->params->{rack_name},
        num_columns => $cols,
        num_rows    => $rows
    });

    $c->{response}->{body} = 1;
    return;
}

sub add_to_box : Chained('protected') PathPart('add_to_box') Args {
    $_[1]->forward('Viroverse::Controller::sidebar','sidebar_to_stash'); #get aliquots from stash
    $_[1]->stash->{template} = 'add_to_box.tt';
    $_[1]->forward('Viroverse::View::TT');
    return;
}

sub x_fer_box : Chained('protected') PathPart('x_fer_box') Args {
    my ($self, $c) = @_;

    $c->stash->{rack} = $c->model("ViroDB::Rack")->find($c->req->args->[0]);;
    $c->stash->{template} = 'x_fer_box.tt';
    $c->forward('Viroverse::View::TT');
    return;
}

sub x_fer_vial : Chained('protected') PathPart('x_fer_vial') Args {
    my ($self, $c) = @_;

    $c->forward('Viroverse::Controller::freezer::summary', 'fetch_box', [$c->req->args->[0]]);
    $c->stash->{int_to_alpha} = [ undef, "A".."Z" ];
    $c->stash->{onclick} = 'none';
    $c->stash->{template} = 'x_fer_vial.tt';
    $c->forward('Viroverse::View::TT');
    return;
}

sub moveVial : Chained('protected') PathPart('moveVial') Args {
    my ($self, $c) = @_;

    my $from = $c->model("ViroDB::BoxPos")->find($c->req->args->[0]);
    my $to = $c->model("ViroDB::BoxPos")->find($c->req->args->[1]);
    my $tube = $from->aliquot;
    if (!$tube) {
        my $error_msg = "Starting position " . $from->location . " is empty";
        $c->detach('Viroverse::Controller::ajax_error', 'make_error', [$error_msg]);
    } elsif ($to->aliquot) {
        my $error_msg = "Destination " . $to->location . " is not empty";
        $c->detach('Viroverse::Controller::ajax_error', 'make_error', [$error_msg]);
    }

    #wrap in transaction to make sure both succeed
    my $txn = $c->model("ViroDB")->schema->txn_scope_guard;

    # Database constraints require us to remove the aliquot from the old box
    # position before adding it to the new box position.
    $from->aliquot(undef);
    $to->aliquot($tube);
    $from->update;
    $to->update;

    # Moving an aliquot is considered to be a positive QC validation that it
    # actually exists.  Note that only aliquots with qc_d false or true will
    # be set to true.  Aliquots with a null qc_d value are left alone, though
    # I'm not sure why.  Currently no aliquots have a null qc_d value, but
    # perhaps they did in the past?
    #
    # I was briefly puzzled by this stanza, and so figured it was worth a
    # comment.  The code was introduced by Norm Fox in df26fb0 amidst a slew
    # of other changes, with no commit message.
    #   -trs, 17 Feb 2017
    if($tube && defined($tube->qc_d())){
        $tube->update({ qc_d => 1 });
    }
    $txn->commit;

    $c->{response}->{body} = 1;
    return;
}

=item checkVisitDate
@description  Package method to check if a visit has already been entered for the supplied patient and date
Given that tubes are often mis-labeled with the date they were entered into the clinic's system rather than the
date the patient was actually in the clinic this will return the visit_id.

@param $patient_id int
@param $visit_date date
@returns visit_id int # -1 if visit not found

=cut

sub checkVisitDate : Chained('base') PathPart('checkVisitDate') Args {
    my ($self, $c) = @_;

    my $patient_id = $c->req->args->[0];
    my $visit_date = $c->req->args->[1];
    my $visit_id = -1;
    my $sql = qq[SELECT visit_id,
                        external_visit_id,
                        sample_name,
                        vol,
                        number_aliq,
                        units
                 FROM viroserve.visit
                 LEFT JOIN
                   (SELECT s.visit_id,
                               tt.name as sample_name,
                               a.vol,
                               u.name as units ,
                               count(a.aliquot_id) as number_aliq
                    FROM viroserve.sample s
                      JOIN viroserve.tissue_type tt USING (tissue_type_id)
                      JOIN viroserve.aliquot a ON (a.sample_id = s.sample_id AND NOT a.is_deleted)
                      JOIN viroserve.unit u USING (unit_id)
                    GROUP BY a.sample_id, tt.name, s.visit_id, a.vol, u.name) as aliquots USING (visit_id)
                 WHERE patient_id = ?
                   AND visit_date >= (date(?) - interval '1 day')
                   AND visit_date <= (date(?) + interval '1 day')
                   AND NOT visit.is_deleted
                ];
    my $st =$c->stash->{session}->{'dbr'}->prepare($sql);
    $st->execute($patient_id, $visit_date, $visit_date);
    my $results_r = $st->fetchall_arrayref({});
    $c->stash->{jsonify} = $results_r;
    $c->forward("Viroverse::View::JSON2");
    return;
}

sub addNewAliquots : Chained('protected') PathPart('addNewAliquots') Args {
    #TODO: obscene to have so much SQL in a controller

    my ($self, $c) = @_;
    my %params = %{$c->req->parameters};

    my $txn = $c->model("ViroDB")->schema->txn_scope_guard;


    # Pull tissue, amount, unit and name values.  Restrict tissue ids to numeric values.
    my @tissues = grep { /^tissue_/ && $params{$_} =~ /^\d+$/ } keys %params;
    my @amounts = grep { /^amount_/ } keys %params;
    my @num_tubes = grep { /^numtubes_/ } keys %params;
    my @units = grep { /^unit_/ } keys %params;
    my @names = grep { /^name_/ } keys %params;

    # Validate patient id, visit date and tissue type id (if any of these values are empty, a server error will occur)
    # TODO: beef up validation of remaining fields...
    my $err_msg;
    if ($params{patient_id} !~ /^(new|\d+)$/ && $params{ex_patient_id} !~ /\w/) {
        $err_msg = "no new or existing patient ID provided";
    }
    elsif (!defined $params{visit_date} || $params{visit_date} !~ /^\d{4}-\d{2}-\d{2}$/) {
        $err_msg = 'Visit date is either blank or not in YYYY-MM-DD format';
    }
    elsif (!@tissues) {
        $err_msg = 'Tissue is blank';
    }
    $c->detach('Viroverse::Controller::ajax_error', 'make_error', [$err_msg]) if $err_msg;

    my @aliquot_ids = ("aliquot");

    # Find or create the patient
    my $patient;
    if ($params{patient_id} eq "new") {
        my $cohort = $c->model("ViroDB::Cohort")->find($params{cohort_id});
        $patient = $cohort->add_to_patients({});
        $patient->add_to_patient_aliases({
            type => "primary",
            cohort => $cohort,
            external_patient_id => $params{ex_patient_id}
        });
        $patient->discard_changes;
    } else {
        $patient = $c->model("ViroDB::Patient")->find($params{patient_id});
    }

    if (!$patient){
        croak "patient not found or couldn't be created!";
    }

    my $visit = $patient->visits->find({ visit_date => $params{visit_date}});
    if (!$visit) {
        $visit = $patient->add_to_visits({ visit_date => $params{visit_date} });
        $visit->discard_changes;
    }

    my $name = defined $params{samp_label} && $params{samp_label} =~ /\S/ ? $params{samp_label} : undef;

    foreach my $tissue (@tissues){
        my ($trash, $rep) = split(/_/, $tissue);
        my $tissue_type_id = $params{$tissue};
        my $amount   = $params{"amount_$rep"} =~ /\S/ ? $params{"amount_$rep"} : undef;
        my $unit_id  = $params{"unit_$rep"} =~ /\S/ ? $params{"unit_$rep"} : undef;
        my $numtubes = $params{"numtubes_$rep"};
        $c->detach('ajax_error','make_error',["missing tube count for $rep", "null numtubes for $rep" ]) unless $numtubes > 0;
        my $additive = defined $params{"additive_$rep"} && $params{"additive_$rep"} =~ /^\d+$/ ? $params{"additive_$rep"} : undef;

        my $samples = $visit->samples->search({
            tissue_type_id => $tissue_type_id,
            additive_id => $additive || undef,
        });
        my $sample = $samples->first;
        die "Ambiguous pre-existing samples" if $samples->next;

        if (!$sample) {
            $sample = $visit->add_to_samples({
                tissue_type_id => $tissue_type_id,
                additive_id => $additive || undef,
            });
            $sample->discard_changes;
        }

        for (my $i = 0 ; $i < $numtubes ; $i++){
            my $aliq = $sample->add_to_aliquots({
                vol => $amount,
                unit_id => $unit_id,
                creating_scientist_id => $c->stash->{scientist}->scientist_id,
                qc_d => 1
            });
            $aliq->discard_changes;
            push @aliquot_ids, $aliq->id;
        }
    }
    $txn->commit;

    $c->forward('Viroverse::Controller::sidebar', 'add', \@aliquot_ids);

    $c->{response}->{body} = 1;
    return;
}

sub renameBox : Chained('protected') PathPart('renameBox') Args {
    my ($self, $c) = @_;
    my $box = $c->model("ViroDB::Box")->find($c->req->params->{box_id});
    my $new_name = $c->req->params->{name};
    $box->update({ name => $new_name });
    $c->{response}->{body} = 1;
    return;
}


sub addToBox : Chained('protected') PathPart('addToBox') Args {
    my ($self, $c) = @_;

    my @result;
    foreach my $place( @{$c->req->args}){
        my (undef, $aliquot_id, $box_pos_id) = split(/_/, $place);
        my $box_pos = $c->model("ViroDB::BoxPos")->find($box_pos_id);
        my $aliquot = $c->model("ViroDB::Aliquot")->find($aliquot_id);

        my $check_add;
        if ($box_pos->aliquot) {
            $check_add = -1;
        } elsif ($aliquot->is_in_freezer) {
            $check_add = -2;
        } else {
            $box_pos->update({ aliquot => $aliquot });
            $check_add = 1;
        }

        if($check_add == 1 || $check_add == -2){ #if vial successfully placed or already in freezer remove from sidebar
            $c->forward('Viroverse::Controller::sidebar', 'remove', ['aliquot', $aliquot_id]);
        }

        push(@result,  $box_pos_id . "_" . $box_pos->name . "_aliquot_" . $aliquot_id . "_" . $check_add);
    }

    $c->{response}->{body} = join("/", @result);
    return;
}

sub undoAdd : Chained('protected') PathPart('undoAdd') Args {
    my ($self, $c) = @_;

    my $box_pos = $c->model("ViroDB::BoxPos")->find($c->req->args->[0]);
    my $aliquot = $box_pos->aliquot;
    my $ret = {
        box_pos => {
            box_pos_id => $box_pos->id,
            pos        => $box_pos->pos,
            name       => $box_pos->name,
        },
        aliquot => $aliquot,
    };
    $c->forward('Viroverse::Controller::sidebar', 'add', ['aliquot', $aliquot->id]); #put aliquot back in perserved que.
    $box_pos->update({ aliquot_id => undef });
    $c->stash->{jsonify} = $ret;
    $c->forward("Viroverse::View::JSON2");
    return;
}

sub moveBox : Chained('protected') PathPart('moveBox') Args {
    my ($self, $c) = @_;

    my $box_id = $c->req->args->[0];
    my $new_rack_id = $c->req->args->[1];
    my $box = $c->model("ViroDB::Box")->find($box_id);
    $box->update({ rack_id => $new_rack_id });

    $c->forward('reorderBoxes', $c->req->params->{rack1_boxes});
    $c->forward('reorderBoxes', $c->req->params->{rack2_boxes});

    $c->response->{body} = 1;
    return;
}

sub updateVials : Chained('protected') PathPart('updateVials') Args {
    my ($self, $c) = @_;

    my %params = %{$c->req->params};

    #grab and ditch non column values from params
    my @ids = split(/\//, $params{keys});
    my $idQs = join (",", map("?", @ids));
    my $ret = $params{return};
    my $assign_sci = $params{scientist_name};
    my $remove = $params{remove};
    my $add_to_freezer = $params{add_to_f};
    delete($params{keys});
    delete($params{remove});
    delete($params{scientist_name});
    delete($params{add_to_f});
    if(defined $assign_sci && $assign_sci ne "multiple"){
        $params{possessing_scientist_id} = Viroverse::db::resolve_external_property($c->stash->{session}, "scientist" , $assign_sci);
    }
    foreach (sort keys(%params)){
        if($params{$_} eq "multiple" || $params{$_} =~ /^\s*$/){
            delete($params{$_});
            next;
        }
        if(!Viroverse::Model::aliquot->validateField($_ , $params{$_})){
            $c->detach('Viroverse::Controller::ajax_error', 'make_error', [$params{$_} . " is not a valid value for $_"]);
        }
    }
    my @check = keys(%params);#make sure there are sill value to write;
    if($#check > -1){
        if($#ids == 0){
            my $aliquot = Viroverse::Model::aliquot->retrieve($ids[0]);
            $aliquot->set(%params);
        }elsif($#ids > 0){
            my @vals;
            my $sql = "UPDATE viroserve.aliquot SET ";
            my @edits;
            my $dbh = Viroverse::Model::aliquot->db_Main;
            foreach(sort(keys(%params))){
                push(@edits , $dbh->quote_identifier($_) . " = ? ");
                push(@vals, $params{$_});
            }
            $sql .=  join(", " , @edits) . " WHERE aliquot_id IN ($idQs)";
            my $st =$c->stash->{session}->{'dbw'}->prepare($sql);
            $st->execute(@vals, @ids);
        }
    }

    if($remove eq "remove"){ #clear out box_pos
        my $sql = "UPDATE freezer.box_pos set aliquot_id = NULL WHERE aliquot_id IN ($idQs)";
        my $st =$c->stash->{session}->{'dbw'}->prepare($sql);
        $st->execute(@ids);
    }
    if($add_to_freezer eq "add"){
        my @not_in;
        foreach my $id(@ids){
            my $a = Viroverse::Model::aliquot->retrieve($id);
            if(!$a->isInFreezer()){
                push(@not_in, $id);
            }
        }
        push(@{$c->session->{sidebar}->{aliquot}}, @not_in);
    }
    $c->response->{body} = 1;
    return;
}

sub deleteBox : Chained('protected') PathPart('deleteBox') Args {
    my ($self, $c) = @_;

    my $box = $c->model("ViroDB::Box")->($c->req->args->[0]);

    if (!$box->is_empty) {
        my $err_msg = "Box " . $box->location . " is not empty so it can't be deleted";
        $c->detach('Viroverse::Controller::ajax_error', 'make_error', [$err_msg]);
    }
    $c->stash->{session}->{'dbw'}->begin_work;

    my $sql = "DELETE FROM freezer.box_pos WHERE box_id = ?";
    my $st = $c->stash->{session}->{'dbw'}->prepare($sql);
    $st->execute($box->box_id());
    $sql = "DELETE FROM freezer.box WHERE box_id = ?";
    $st = $c->stash->{session}->{'dbw'}->prepare($sql);
    $st->execute($box->box_id());
    $c->stash->{session}->{'dbw'}->commit;
    $c->response->{body} = 1;
    return;
}

1;
