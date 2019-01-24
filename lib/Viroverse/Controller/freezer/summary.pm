package Viroverse::Controller::freezer::summary;

use strict;
use warnings;
use base 'Viroverse::Controller';
use Catalyst::ResponseHelpers;

sub section { 'freezer' }

sub base : ChainedParent PathPart('summary') CaptureArgs(0) { }

sub index : Chained('base') PathPart('') Args(0) {
    my ($self, $c) = @_;
    $c->stash( template => 'manage_freezer.tt' );
    return $c->detach( $c->view('TT') );
}

sub freezer_ajax : Chained('base') PathPart('freezer_ajax') Args {
    my ($self, $c) = @_;

    # create freezer object using passed id.  abort request and return
    # if freezer does not exist.
    my $freezer_id = $c->req->args->[0];
    return 0 unless (defined $freezer_id && $freezer_id =~ /^\d+$/);
    my $freezer = $c->model("ViroDB::Freezer")->find($freezer_id);

    # create array of racks within freezer
    my @racks = $freezer->racks->in_order;
    my @rck_hsh_arr;
    foreach my $r (@racks){
        my $rack_config;
        my $orientation;
        if ($freezer->upright_chest eq 'c') {
            $rack_config = $r->num_rows . " Shelves";
        }
        elsif ($freezer->upright_chest eq 'u') {
            $rack_config = $r->num_rows . " Rows X " . $r->num_columns . " Columns";
        }
        push(@rck_hsh_arr,
             {rack_id   => $r->rack_id,
              name      => $r->name,
              num_boxes => $r->boxes->count,
              config    => $rack_config,
              order_key => $r->order_key,
              rows      => $r->num_rows,
              cols      => $r->num_columns,
             });
    }

    # set values to return and return them
    my $freezer_ref =
        {freezer_id         => $freezer->freezer_id,
         name               => $freezer->name,
         location           => $freezer->location,
         description        => $freezer->description,
         upright_chest      => $freezer->upright_chest,
         cane_alpha_int     => $freezer->cane_alpha_int,
         racks              => \@rck_hsh_arr,
        };
    $c->stash->{jsonify} = $freezer_ref;
    $c->forward("Viroverse::View::JSON2");
    return;
}

sub rack : Chained('base') PathPart('rack') Args {
    my ($self, $c) = @_;
    my $rack  = $c->model("ViroDB::Rack")->find($c->req->args->[0]);
    $c->stash->{rack} = $rack;
    my $box_id = $c->req->args->[1];
    if ($box_id) {
        $c->stash->{box_id} =  $box_id;
    }
    $c->stash->{template} = 'rack.tt';
    $c->forward('Viroverse::View::TT');
    return;
}

sub rackAjax : Chained('base') PathPart('rackAjax') Args {
    my ($self, $c) = @_;

    my $rack  = $c->model("ViroDB::Rack")->find($c->req->args->[0]);
    my @boxes;
    foreach my $box (($rack->boxes)){
        push(@boxes, {
                    box_id => $box->box_id,
                    name => $box->name,
                    });
    }

    my $rack_ref = {
                        rack_id => $rack->rack_id(),
                        name => $rack->name(),
                        num_rows => $rack->num_rows,
            num_columns => $rack->num_columns,
                        freezer => { id => $rack->freezer->id, name => $rack->freezer->name, upright_chest => $rack->freezer->upright_chest },
            boxes => \@boxes,
                    };

    $c->stash->{jsonify} = $rack_ref;
    $c->forward("Viroverse::View::JSON2");
}

sub fetch_box : Private {
    my ($self, $c) = @_;

    my $box = $c->model("ViroDB::Box")->find($c->req->args->[0]);

    my @box_pos = $box->search_related('box_positions', {}, { order_by => 'pos' });
    my @box_pos_hr;
    foreach my $pos (@box_pos){
        my $tube = $pos->aliquot;
        my $sample;
        my $samp_name;
        if ($tube) {
            $sample = $tube->sample;
            $samp_name = $sample->to_string;
        }
        my $bp_hr = {
            box_pos_id => $pos->id,
            sample => $sample,
            sample_name => $samp_name,
            status => $pos->status,
            aliquot_id => $tube && $tube->id,
            name => $pos->name,
            pos => $pos->pos,
        };
        push(@box_pos_hr, $bp_hr);
    }

    $c->stash->{box} = {
                        box_id => $box->id,
                        location => $box->location,
                        num_rows => $box->num_rows,
                        num_columns => $box->num_columns,
                        positions => \@box_pos_hr,
                        is_empty => $box->is_empty,
                     };
}

sub box : Chained('base') PathPart('box') Args {
    my ($self, $c) = @_;

    $c->forward('fetch_box', [$c->req->args->[0]]);
    $c->stash->{onclick} = $c->req->args->[1];

    $c->stash->{template} = 'freezer_box.tt';
    $c->stash->{int_to_alpha} = { 1 => "A", 2 => "B", 3 => "C", 4 => "D", 5 => "E",
                                  6 => "F", 7 => "G", 8 => "H", 9 => "I", 10 => "J", };
    $c->forward('Viroverse::View::TT');
}

sub aliquot_ajax : Chained('base') PathPart('aliquot_ajax') Args {
    my ($self, $c) = @_;

    my @aliquot_ids = @{$c->req->args};
    my @aliquots = Viroverse::Model::aliquot->retrieve_many(@aliquot_ids);

    $c->stash->{jsonify} = \@aliquots;
    $c->forward("Viroverse::View::JSON2");
}

sub enum : Chained('base') PathPart('enum') Args {
    my ($self, $c) = @_;

    my $find_what = $c->req->args->[0];
    my $from_what = $c->req->args->[1];
    my $id = $c->req->args->[2];
    unless (
        ($find_what eq "box"  && $from_what eq "rack") ||
        ($find_what eq "rack" && $from_what eq "freezer")
    ) {
        return ClientError($c);
    }

    my $model = 'ViroDB::' . ucfirst $find_what;
    my @objs = $c->model($model)->search({ $from_what . "_id" => $id })->in_order->all;
    my @json_data = map { { id=>$_->id, name=>$_->name } } @objs;

    $c->stash->{jsonify} = \@json_data;
    $c->forward("Viroverse::View::JSON2");

}

1;
