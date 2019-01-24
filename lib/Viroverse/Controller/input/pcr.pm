package Viroverse::Controller::input::pcr;
use base 'Viroverse::Controller';

use strict;
use warnings;
use 5.018;

use Carp;
use File::chdir;
use File::Temp;
use Viroverse::db;
use Viroverse::Model::copy_number;
use Viroverse::Model::enzyme;
use Viroverse::Model::gel;
use Viroverse::Model::pcr;
use Viroverse::Model::pcr_pool;
use Viroverse::Model::scientist;
use List::AllUtils qw< uniq >;
use Viroverse::SQL::Library;

=head1 NAME

Viroverse::Controller::input::pcr - Holds Catalyst actions under /input/pcr

=head1 SYNOPSIS

See L<Viroverse>

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=item begin
=cut
sub section {
    return 'input';
}

sub subsection {
    return 'sequence';
}

sub pool : Local {
    my ($self, $context) = @_;

    $context->forward('Viroverse::Controller::sidebar','sidebar_to_stash');

    $context->stash->{find_a} = [
        {name => 'pos_pcr', label => 'PCR product'}
    ];

    $context->stash->{template} = 'pcr_pool.tt';

}

sub pool_add : Local {
    my ($self, $context) = @_;

    my @pool_pcrs = uniq $context->request->param('pos_pcrbox');
    $context->detach('user_error',["At least two PCR products required"]) unless @pool_pcrs > 1;

    my @pool_members = Viroverse::Model::pcr->retrieve_many(@pool_pcrs);
    $context->detach('user_error',["Failed to find all PCR products"])
        unless @pool_pcrs == @pool_members;

    my $sci = Viroverse::Model::scientist->search_single( $context->request->param('scientist_name') );
    $context->detach('user_error',["Could not find scientist ".$context->request->param('scientist_name')]) unless $sci;

    my $date = $context->request->param('pooling_date');
    $context->detach('user_error',["Date must in ISO format (YYYY-MM-DD)"]) unless Viroverse::db::validate_date($date);

    Viroverse::CDBI->db_Main->begin_work;

    my $pool = Viroverse::Model::pcr_pool->insert({
        date_completed => scalar $context->request->param('pooling_date'),
        scientist_id => $sci,
        notes => scalar $context->request->param('pooling_notes')
    });

    my $pcr = Viroverse::Model::pcr->insert({
        pcr_template_id => $pool_members[0]->pcr_template_id,
        date_completed => scalar $context->request->param('pooling_date'),
        scientist_id => $sci,
        pcr_pool_id => $pool
    });

    $pool->add_to_pcr_products({ pcr_product_id => $_ })
        for @pool_members;

    Viroverse::CDBI->db_Main->commit;
    push @{$context->session->{sidebar}->{pcr_pool}},$pcr->give_id;

}

sub reamp : Local {
    my ($self, $context) = @_;

    $context->stash->{find_a} = [
        {name => 'pos_pcr', label => 'PCR product'}
    ];

    $context->forward('Viroverse::Controller::sidebar','gel_sidebar_to_stash');
    $context->forward('Viroverse::Controller::sidebar','sidebar_to_stash');

    $context->stash->{enzymes} = [ Viroverse::Model::enzyme->search_pcr ];
    $context->stash->{protocols} = [ $context->model('protocol')->search_by_type('pcr') ];
    $context->stash->{template} = 'pcr_reamp.tt';
}

sub reamp_add : Local {
    my ($self, $context) = @_;
    my %p = %{$context->req->params};
    my @reamped;

    my $sci = Viroverse::Model::scientist->search_single( $context->request->param('scientist_name') );
    $context->detach('user_error',["Could not find scientist ".$context->request->param('scientist_name')]) unless $sci;

    my $date_completed = $p{'pcr_completed_date'};
    $context->detach('user_error',["Date format must be YYYY-MM-DD"]) unless $date_completed =~ m/\d{4}-\d\d-\d\d/;

    my %boxes;
    foreach my $k (keys %p) {
        (my $box) = $k =~ /(.*box\d+)/;
        $boxes{$box} = 1 if $box;
    }
    $context->detach('user_error',["no replicates defined","need replicates"]) if (! keys %boxes ) ;

    Viroverse::CDBI->db_Main->begin_work;
    foreach my $pcr_box (keys %boxes) {
        my $template_pcr_id = (split /box/,$pcr_box)[1];
        my $template_pcr = Viroverse::Model::pcr->retrieve($template_pcr_id);
        $context->detach('user_error',["Invalid template","non-existing pcr_product_id:".$template_pcr_id]) if (! $template_pcr ) ;

        my $reamp_round_no = defined $template_pcr->reamp_round ? $template_pcr->reamp_round + 1 : 1;

        my $vmatch = $pcr_box.'vol';
        foreach my $vol (grep /$vmatch/, keys %p) {
            (my $vol_num) = $vol =~ m/(\d+)$/;

            my $template_volume = $p{$pcr_box.'vol'.$vol_num};
            $context->detach('user_error',["illegal volume for volume # $vol_num"] ) if ($template_volume !~ m/^(\d+(\.\d+)?)$|^(\.\d+)$/ );

            my $units = $p{$pcr_box.'unit'.$vol_num}
                or return $context->detach('user_error',["unspecified units for volume # $vol_num"]);
            my $unit_id = Viroverse::db::resolve_external_property( $context->stash->{session}, 'unit',$units)
                or return $context->detach('user_error',["could not resolve unit $units"]);

            my $repls = $p{$pcr_box.'repl'.$vol_num}
                or return $context->detach('user_error',["unspecified number of replicates for volume # $vol_num"]);

            foreach my $repl_count (1..$repls) {
                my $templ = Viroverse::Model::pcr_template->insert({
                    unit_id => $unit_id,
                    volume  => $template_volume,
                    scientist_id => $sci,
                    date_completed => $date_completed,
                    pcr_product_id => $template_pcr
                });
                my $pcr = Viroverse::Model::pcr->insert({
                    pcr_template_id => $templ,
                    reamp_round => $reamp_round_no,
                    date_completed => $date_completed,
                    scientist_id => $sci,
                    notes => $p{pcr_notes},
                    replicate => $repl_count,
                    enzyme_id => $p{pcr_enzyme},
                    hot_start => $p{pcr_hot},
                    genome_portion => $template_pcr->genome_portion,
                    round => $template_pcr->round,
                    ($p{pcr_protocol}
                        ? (protocol_id => $p{pcr_protocol})
                        : ()),
                    # XXX: Allow for endpoint_dilution here?  I don't think
                    # it's necessary.  -trs, 13 May 2014
                });
                push @reamped, $pcr;
                foreach my $primer ($template_pcr->primers) {
                    $pcr->add_to_primers({primer_id => $primer});
                }
            }
        }
    }

    Viroverse::CDBI->db_Main->commit;

    $context->forward('Viroverse::Controller::input', 'gel_add_label',['pcr',@reamped]);
    $context->forward('Viroverse::Controller::sidebar','gel_sidebar_to_stash');
    $context->forward('Viroverse::Controller::sidebar','sidebar_to_stash');

}

sub calc_copy_number : Private {
    my ($self, $c, $gel_lanes, $save_results) = @_;

    my %resHash;
    if (@$gel_lanes) {
        state $library = Viroverse::SQL::Library->new;
        my $dbh  = $c->stash->{session}->{dbr};
        my $sql  = $library->pcr_ancestors( gel_lanes => $gel_lanes );
        my $rows = $dbh->selectall_arrayref( $sql, { Slice => {} }, @$gel_lanes );
        %resHash = %{ $self->_buildCopyNumGrpHash($rows, "gel_lane_id") };
    } else {
        warn "No gel_lanes passed so nothing to do";
    }

    my %q_key;
    my @keys = sort keys(%resHash);
    for (my $i = 0 ; $i < scalar(@keys) ; $i++){
        $q_key{$keys[$i]} = $i;
    }

    my $q_src_txt = "";
    foreach my $temp (@keys) {
        $q_src_txt .= "#" . $q_key{$temp};
        $q_src_txt .= "\n" . join("\t", @{$resHash{$temp}{q}{dils}});
        $q_src_txt .= "\n" . join("\t", @{$resHash{$temp}{q}{pcrs}});
        $q_src_txt .= "\n" . join("\t", @{$resHash{$temp}{q}{pos}});
        $q_src_txt .= "\n\n";
    }

    local $CWD = '/tmp/';
    my $tfh = File::Temp->new(TEMPLATE => 'quality_src.txt-XXXX');
    print $tfh $q_src_txt;

    my $Qresults =  `$Viroverse::config::quality $tfh`;

    my @Qres = split (/Results for/, $Qresults);
    foreach my $res (@Qres){
        if($res =~ /"\.\.\./){
            my $temp_idx = $`;
            my $rest = $';
            $temp_idx =~ s/\s|"//g;# not sure how these started showing up but they do cause problems
            my $template = $keys[$temp_idx];
            if($res =~ /No solution found./){
                $resHash{$template}{copy_num} = "n/a";
                $resHash{$template}{std_err} = "n/a";
                $resHash{$template}{sensitivity} = "No solution found.";
                $resHash{$template}{result} = "Results for " . $res;
            }else{
                $rest =~ /Standard Error:/;
                my $copy_num = $`;
                $rest = $';
                $copy_num =~ s/# of copies per unit:|\s//g ;
                $rest =~ /Chi\^2 goodness of fit:/;
                my $std_err = $`;
                $rest = $';
                $rest =~ /Sensitivity analysis:/;
                my $sensitivity = $';
                $std_err =~ s/\s//g; #remove all whitespace from "floats"
                $copy_num =~ s/\s//g;
                $resHash{$template}{copy_num} = $copy_num;
                $resHash{$template}{std_err} = $std_err;
                $resHash{$template}{sensitivity} = $sensitivity;
                $resHash{$template}{result} = "Results for " . $res;
            }
        }
    }

    $c->stash->{quality} = \%resHash;

    $c->forward('Viroverse::Controller::input::pcr', '_writeQualCopyNum')
        if $save_results;
}

sub groupPCRs4Qual {
    my ($self, $c, $pcr_ids) = @_;
    warn "No pcr products passed so nothing to do"
        if not @$pcr_ids;

    state $library = Viroverse::SQL::Library->new;
    my $dbh  = $c->stash->{session}->{dbr};
    my $sql  = $library->pcr_ancestors( pcrs => $pcr_ids );
    my $rows = $dbh->selectall_arrayref( $sql, { Slice => {} }, @$pcr_ids );

    $c->stash->{quality} = $self->_buildCopyNumGrpHash($rows, "start_pcr");
}

sub runCopyNumber : Local {
    my ($self, $c) = @_;

    my %params = %{$c->req->params};
    my @quality = grep { /-q$/ } keys %params;
    my @gel_lanes;
    foreach my $q (@quality){
        if($params{$q} eq "yes"){
            $q =~ s/-q$//;
            my @lanes  = lc(ref($params{$q . "_lane"})) eq "array"?@{$params{$q. "_lane"}}: ($params{$q. "_lane"});
            push(@gel_lanes, @lanes);
        }
    }
    if(scalar(@gel_lanes) < 1){
        $c->stash->{error} = 'Not Enough lanes passed to run Quality Copy number analysis';
        $c->stash->{template} = 'copy_num_set_up.tt';
        return;
    }
    $c->forward('Viroverse::Controller::input::pcr', 'calc_copy_number', [\@gel_lanes, 1]);
}


sub _writeQualCopyNum {
    my ($self, $c) = @_;

    $c->forward('Viroverse::Controller::sidebar','sidebar_to_stash');
    my @found_pos_pcr = grep {$_->is_positive} @{$c->stash->{pcr}};
    if (defined $c->stash->{to_gel} && defined $c->stash->{to_gel}->{pcr}) {
        @found_pos_pcr = uniq(
            @found_pos_pcr,
            grep {$_->is_positive}  @{$c->stash->{to_gel}->{pcr}}
        );
    }
    @{$c->stash->{pos_pcr}} = uniq(@found_pos_pcr, @{$c->stash->{pos_pcr}});
    @{$c->session->{sidebar}->{pcr_more}} = map {$_->pcr_product_id} @{$c->stash->{pos_pcr}};
    my %q_res = %{$c->stash->{quality}};
    foreach my $q_key (keys(%q_res)){
        next if $q_res{$q_key}->{copy_num} eq "n/a"; #don't write uncalculated values.
        my @key_parse = split(/\//, $q_key);
        my $rec_addition = -1; #TODO build function to calculate this
        Viroverse::Model::copy_number->save($key_parse[0], $q_res{$q_key}->{copy_num},$q_res{$q_key}->{std_err}, $q_res{$q_key}->{sensitivity}, $c->stash->{scientist}->scientist_id, $q_key, $rec_addition, $q_res{$q_key}->{lanes});
    }

    $c->stash->{template} = 'copy_num_results.tt';
}

sub showCopyNumResults : Local {

    my ($self, $c) = @_;

    $c->forward('Viroverse::Controller::sidebar','sidebar_to_stash');
    $c->stash->{quality} = $c->session->{sidebar}->{quality}; # quality stores a hash ref of hash refs not an array of ids so side_bar_to_stash won't grab it
    delete($c->session->{sidebar}->{quality});#now that you've got what you need clean up after yourself :^)
    if(!defined($c->stash->{quality})){
       $c->stash->{error} = 'No Recent Copy Number Results Were Found';
    }

    $c->stash->{template} = 'copy_num_results.tt';
}

sub _buildCopyNumGrpHash {
    my ($self, $db_result, $id_type) = @_;
    my $resHash = {};
    my %rowHash;

    my $id_column = $id_type eq 'gel_lane_id'? $id_type : 'start_pcr';
    foreach my $row (@{$db_result}){
        $rowHash{$row->{$id_column}}->{start_pcr} = $row->{start_pcr}; #is present and the same for all gell lanes
        $rowHash{$row->{$id_column}}->{pos_pcr} =  $row->{pos_pcr}?1:0;
        $rowHash{$row->{$id_column}}->{volume} =  $row->{volume} unless $row->{round} != 1;
        if($row->{round} == 1){
            if(defined($row->{extraction_id})){
                $rowHash{$row->{$id_column}}->{template_id} = "extraction_" . $row->{extraction_id};
            }elsif(defined($row->{rt_product_id})){
                $rowHash{$row->{$id_column}}->{template_id} = "rt_" . $row->{rt_product_id};
            }elsif(defined($row->{sample_id})){
                $rowHash{$row->{$id_column}}->{template_id} = "sample_" . $row->{sample_id};
            }elsif(defined($row->{bisulfite_converted_dna_id})){
                $rowHash{$row->{$id_column}}->{template_id} = "bisulfite_" . $row->{bisulfite_converted_dna_id};
            }
        }
        push(@{$rowHash{$row->{$id_column}}->{primers}}, $row->{primers});
        push(@{$rowHash{$row->{$id_column}}->{enzymes}}, $row->{enzyme_id});
        push(@{$rowHash{$row->{$id_column}}->{round}}, $row->{round});
    }

    foreach my $id (keys(%rowHash)){
        my $pcr_id;
        my $q_key = Viroverse::Model::copy_number->writeKey($rowHash{$id}{template_id}, $rowHash{$id}{primers}, $rowHash{$id}{enzymes});
        my $vol =  $rowHash{$id}{volume};
        if(!defined($resHash->{$q_key}->{volumes}->{$vol})){ # these need to default as empty array_refs otherwise things go boom later if no data to push
            $resHash->{$q_key}->{volumes}->{$vol}->{pcrs} = [];
            $resHash->{$q_key}->{volumes}->{$vol}->{pos} = [];
        }

        if($id_type eq 'gel_lane_id'){
            $pcr_id = $rowHash{$id}{start_pcr};
            push(@{$resHash->{$q_key}->{lanes}} , $id);
            push(@{$resHash->{$q_key}->{volumes}->{$vol}->{lanes}}, $id);

        }else{ #is pcr
            $pcr_id = $id;
        }
        $resHash->{$q_key}->{template_id} = $rowHash{$id}{template_id};
        $resHash->{$q_key}->{primers} = $rowHash{$id}{primers};
        $resHash->{$q_key}->{enzymes} = $rowHash{$id}{enzymes};
        $resHash->{$q_key}->{name} = Viroverse::Model::copy_number->parseKey($q_key) unless defined($resHash->{$q_key}->{name}); #no need to do this more than is necessary
        push(@{$resHash->{$q_key}->{pcrs}} , Viroverse::Model::pcr->retrieve($pcr_id));
        push(@{$resHash->{$q_key}->{volumes}->{$vol}->{pcrs}}, $pcr_id);
        push(@{$resHash->{$q_key}->{volumes}->{$vol}->{pos}}, $rowHash{$id}{pos_pcr}) unless !$rowHash{$id}{pos_pcr}; #only add positives
    }

    foreach my $temp( keys(%{$resHash})){
        my @vols = sort { $b <=> $a } keys %{$resHash->{$temp}->{volumes}};
        my @pcrs = map {scalar(@{$resHash->{$temp}->{volumes}->{$_}->{pcrs}})} @vols;
        my @pos = map {scalar(@{$resHash->{$temp}->{volumes}->{$_}->{pos}})} @vols;
        $resHash->{$temp}->{q}->{dils} = \@vols;
        $resHash->{$temp}->{q}->{pcrs} = \@pcrs;
        $resHash->{$temp}->{q}->{pos} = \@pos;
    }
    return $resHash;
}

sub copy_num_set_up : Local {
    my ($self, $context) = @_;
    $context->stash->{template} = 'copy_num_set_up.tt';
}

sub copy_number_gels : Local {
    my ($self, $context) = @_;
    $context->forward('Viroverse::Controller::sidebar','sidebar_to_stash');
    $context->stash->{template} = 'copy_num_set_up_gels.tt';

    my @gels = map {Viroverse::Model::gel->retrieve($_)} @{$context->request->args()};

    if (scalar(@gels) < 1) {
        $context->stash->{notice} = "Need Gels to run copy number...";
        return;
    }

    my @gel_lanes;
    foreach my $gel (@gels){
        my @lanes = $gel->lanes;
        push(@gel_lanes, @lanes);
    }

    $context->forward('Viroverse::Controller::input::pcr', 'calc_copy_number', [\@gel_lanes]);
    my %q_res = defined($context->stash->{quality})?%{$context->stash->{quality}}:();
    my %bad_pcrs;
    my %qualJSON;
    foreach my $q_key (keys(%q_res)){
        my @pcrs = @{$q_res{$q_key}->{pcrs}};
        my %pcr_check =    map {$_->pcr_product_id => 1} @pcrs;
        my @pcr_ids = keys(%pcr_check);
        $qualJSON{$q_key}{pcrs} = \@pcr_ids;
        $qualJSON{$q_key}{dils} = $context->stash->{quality}->{$q_key}->{q}->{dils};
        $qualJSON{$q_key}{sum_pcr} = [];
        $qualJSON{$q_key}{sum_pos} = [];
        if(scalar(@pcr_ids) < scalar(@pcrs)){  # same pcr product run on multiple gels;
            %bad_pcrs = (%bad_pcrs, %pcr_check);
            $context->stash->{rm_from_quality}->{$q_key} = $q_res{$q_key};
        }
    }

    $context->stash->{gels} = \@gels;
    $context->stash->{bad_pcrs} = \%bad_pcrs;
    $context->stash->{qualityJSON} = Viroverse::View::JSON2->encode_json($context, {jsonify =>  \%qualJSON});
}


sub fetchCopyNumber : Local{
    my ($self, $c) = @_;

    my @products = @{$c->req->args()};
    my %copy_num_data;
    my @pcrs;
    my @cp_nums;
    foreach my $product (@products){
        my $type = $product;
        $type =~ s/\d|box//g;
        my $id = $product;
        $id =~ s/\D//g;
        if($type eq 'pos_pcr'){
            push(@pcrs, $id);
        }else{
            my $obj = $Viroverse::Controller::need::instantiate_for{$type}($c,$id);
            push (@cp_nums, ($obj->copy_numbers()));
        }
    }
    if(scalar(@pcrs) > 0 ){
        $c->forward('Viroverse::Controller::input::pcr', 'groupPCRs4Qual', [\@pcrs]);
        my $cpn_keys = join("', '" , keys(%{$c->stash->{quality}}));
        push(@cp_nums, (Viroverse::Model::copy_number->retrieve_from_sql( qq{ key IN ('$cpn_keys') ORDER BY key, date_created DESC})));
    }
    foreach my $cpn(@cp_nums){
        if(!exists($copy_num_data{$cpn->key()})){
            $copy_num_data{$cpn->key()}{name} = $cpn->pcr_name;
        }
        $copy_num_data{$cpn->key()}{$cpn->copy_number_id()} = $cpn;
    }

    $c->stash->{jsonify} = \%copy_num_data;
    $c->forward("Viroverse::View::JSON2");
}


sub index : Private {
    my ($self, $context) = @_;
    $context->forward('Viroverse::Controller::input','PCR');
}

1;
