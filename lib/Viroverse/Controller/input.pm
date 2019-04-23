package Viroverse::Controller::input;
use base 'Viroverse::Controller';

use strict;
use warnings;
use 5.018;

use Viroverse::Model::extraction;
use Viroverse::Model::unit;
use Viroverse::patient;
use Viroverse::Model::rt;
use Viroverse::Model::bisulfite_converted_dna;
use Viroverse::sample;
use Viroverse::Model::scientist;
use Viroverse::Logger qw< :log :dlog >;
use Catalyst::ResponseHelpers;
use List::Util qw< pairgrep pairvalues uniq >;
use Try::Tiny;

use Fasta;

use Image::Info;
use Imager;
use List::MoreUtils qw< none >;

use Data::Dump;
use Carp;

=head1 NAME

Viroverse::Controller::input - Holds Catalyst actions under /input to create data in Viroverse

=head1 SYNOPSIS

See L<Viroverse>

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=item begin
    (will) validate that all data is present and forwards to appropriate controller
    will also verify authn/authz in the future
=cut

sub auto : Private {
    my ($self,$context) = @_;
    return Forbidden($context) unless $context->stash->{scientist}->can_edit;
    $context->stash->{cohorts} = $context->model("ViroDB::Cohort")->list_all;
    return 1;
}

sub index : Private {
    my ($self, $context) = @_;
    $context->stash->{template} = 'input_home.tt';
}

sub section    { 'input' }
sub subsection { 'sequence' }   # Default to sequencing subsection

sub extraction : Local {
    my ($self, $context) = @_;

    #validate
    if (!exists $context->session->{sidebar}->{'sample'} || @{$context->session->{sidebar}->{'sample'}} == 0 ) {
        $context->stash->{notice} = q[You need to pick something to extract first...];
    }

    $context->forward('Viroverse::Controller::sidebar','sidebar_to_stash');
    $context->forward('Viroverse::Controller::sidebar','extraction_prepare');

    $context->stash->{find_a} = [{name => 'sample', label => 'sample'}];

    $context->stash->{tissue_types} = Viroverse::sample->list_tissue_types($context->stash->{session});
    $context->stash->{protocols} = [ $context->model('protocol')->search_by_type('extraction') ];
    $context->stash->{template} = 'extraction.tt';
}

sub extraction_post : Local {
    my ($self, $context) = @_;

    my %name_for = (
        scientist_name         => 'scientist_id',
        extraction_notes       => 'notes',
        extraction_amount_used => 'amount',
        extraction_amount_used_type => 'unit_id',
        extraction_date        => 'date_completed',
        extraction_proto       => 'protocol_id',
        extraction_concentrated=> 'concentrated',
        extraction_concentration=> 'concentration',
        extraction_concentration_unit=> 'concentration_unit_id',
        extraction_molecule    => 'extract_type_id',

        extraction_eluted_vol      => 'eluted_vol',
        extraction_eluted_vol_unit => 'eluted_vol_unit_id',
     );

    my %resolve = (
        unit_id => 'unit_id',
        scientist_id => 'scientist_id', 
        extract_type_id => 'extract_type_id',
        concentration_unit_id => 'unit_id',
        eluted_vol_unit_id => 'unit_id'
    );

    my @required = qw(
        scientist_name
        extraction_amount_used
        extraction_amount_used_type
        extraction_date
        extraction_concentrated
        extraction_molecule
    );

    foreach my $field_name (@required) {
        $context->detach('user_error',["$field_name is a required field","missing $field_name"]) unless length($context->req->param($field_name)) > 0  ;
    }

    $context->detach('user_error',["Date should be in ISO format (YYYY-MM-DD)","bad extraction_date"]) unless Viroverse::db::validate_date( $context->req->param('extraction_date') );

    my @new_extractions;
    Viroverse::CDBI->db_Main->begin_work;
    #the same extraction data may apply to more than one sample
    foreach my $sample_id ( $context->req->param('samplebox') ) {
        my %extract_prop;

        while ( my ($form_name,$db_name) = each %name_for) {
            $extract_prop{$db_name} = $resolve{$db_name} ? Viroverse::db::resolve_external_property($context->stash->{session},substr($resolve{$db_name},0,-3), $context->req->param($form_name) )  : $context->req->param($form_name);
        }
        if ( length($extract_prop{'concentration'}) < 1 ) {
            delete $extract_prop{'concentration'};
            delete $extract_prop{'concentration_unit_id'};
        }

        unless ($extract_prop{'eluted_vol'} > 0) {
            delete $extract_prop{$_}
                for qw(eluted_vol eluted_vol_unit_id);
        }

        # Patching a bug: the protocol_id key is initialized above, in the
        # 'each %name_for' loop. If we don't get a protocol from the form
        # ('other' selected) we need to delete the key from the hash so CDBI
        # doesn't try to insert an empty string into an integer column.
        # Someday this controller won't exist anymore! ~ silby@ 2017-04-27
        if ($context->req->param('extraction_proto')) {
            $extract_prop{protocol_id} = $context->req->param('extraction_proto');
        } else {
            delete $extract_prop{protocol_id};
        }

        $extract_prop{sample_id} = $sample_id;
        my $extract = Viroverse::Model::extraction->insert(\%extract_prop);
        push @new_extractions,$extract->extraction_id;
    }

    Viroverse::CDBI->db_Main->commit;
    push @{ $context->session->{sidebar}->{extraction} }, @new_extractions;

    #load sidebar data
    $context->forward('Viroverse::Controller::sidebar','extraction');

}

sub RT : Local {
    my ($self, $context) = @_;

    $context->forward('Viroverse::Controller::sidebar','sidebar_to_stash');

    if (!exists $context->stash->{extraction}) {
        $context->stash->{notice} = "Need an RNA template to record a new reaction"
    }

    my @for_rt = grep { $_->extract_type_id->name eq 'RNA' } @{$context->stash->{extraction}} ;

    if (scalar @for_rt == 0) {
        $context->stash->{notice} = "Need an RNA template to record a new reaction"
    } else {
        $context->stash->{for_rt} = \@for_rt;
    }

    $context->stash->{rt_enzymes} = [ Viroverse::Model::enzyme->search_rt ];
    $context->stash->{find_a} = [{name => 'extraction.rna', label => 'RNA extraction'}];
    $context->stash->{template} = 'RT.tt';
}

sub rt_add : Local {
    my ($self, $context) = @_;

    my %params = %{$context->req->params};

    my @required = qw[RT_date_completed RT_enzyme_id scientist_name];

    foreach my $field_name (@required) {
            $context->detach('user_error',["$field_name is a required field","missing $field_name"]) unless length($params{$field_name}) > 0  ;
    }
    if ($params{ratio_toggle} eq "special" 
            and not (length($params{ratio_special_rna}) 
                and length($params{ratio_special_cdna}))) 
    {
        $context->detach('user_error',["Special RNA:cDNA ratio must be specified", "missing ratio element".length($params{ratio_special_rna})]);
    }

    $context->detach('user_error',["Date should be in ISO format (YYYY-MM-DD)","bad RT_date_completed"]) unless Viroverse::db::validate_date( $context->req->param('RT_date_completed') );

    my @new_rt;
    Viroverse::CDBI->db_Main->begin_work;
    foreach my $extraction_id ( $context->req->param('extractionbox') ) {
        my %rt_product;

        #fields prefixed with RT_ can be stuck directly into the table
        foreach my $field ( grep {s/RT_//} $context->req->param() ) {
            $rt_product{$field} = $context->req->param("RT_$field") if length($context->req->param("RT_$field"));
        }
        if ($context->req->param("ratio_toggle") eq "default") {
            $rt_product{rna_to_cdna_ratio} = 0.5;
        } else {
            $rt_product{rna_to_cdna_ratio} = $context->req->param("ratio_special_rna") / $context->req->param("ratio_special_cdna");
        }

        #has_a fields require a real object (I think)
        my @scientists = Viroverse::Model::scientist->search({name => scalar $context->req->param('scientist_name')} );
        if (@scientists == 1) {
            $rt_product{scientist_id} = $scientists[0];
        } else {
            #invalid scientist...
        }
        $rt_product{extraction_id} = $extraction_id;
        my $rt = Viroverse::Model::rt->insert(\%rt_product);
        $context->detach('mk_error',['Making RT failed from '.Data::Dump::dump(\%rt_product)]) unless defined $rt;
        my %used_primers;
        foreach my $primer_field ( grep m/primer/, $context->req->param() ) {
            my $primer_name = $context->req->param($primer_field);
            $context->detach('user_error',["blank primer name not permitted","blank $primer_field"]) if $primer_name eq '';
            if ($used_primers{$primer_name}) {
                $context->detach('user_error',["duplicate primer $primer_name","duplicate primer $primer_name"]);
            } else {
                $used_primers{$primer_name} = 1;
            }
            my @primer_results = Viroverse::Model::primer->search({ name => $primer_name } ) ; 
            if (@primer_results ) {
                $rt->add_to_primers({primer_id => $primer_results[0]});
            } else {
                $context->detach('user_error',["Could not find primer ".$primer_name,'']);
            }

        } 

        push @new_rt, $rt->give_id;
    }

    Viroverse::CDBI->db_Main->commit;
    push @{$context->session->{sidebar}->{rt}} , @new_rt;


}

sub bisulfite_conversion : Local {
    my ($self, $context) = @_;
    $context->forward('Viroverse::Controller::sidebar','sidebar_to_stash');

    $context->stash->{protocols} = [ $context->model('protocol')->search_by_type('bisulfite_conversion') ];
    $context->stash->{for_conversion} = [ grep { $_->extract_type_id->name eq 'DNA' } @{$context->stash->{extraction}} ] ;
    $context->stash->{find_a} = [
        {name => 'extraction.dna', label => 'DNA extraction'},
        {name => 'rt_product', label => 'cDNA'},
        {name => 'sample.dna', label => 'DNA sample'},
    ];
    $context->stash->{template} = 'bisulfite_conversion.tt';
}

sub bisulfite_conversion_add : Local {
    my ($self, $context) = @_;
    
    my %params = %{$context->req->params};
    my @template_params = grep /box$/, keys %params;
    my ($scientist) = Viroverse::Model::scientist->search({ name => $params{scientist_name} });
    my $txn = Viroverse::CDBI->txn_scope_guard;
    my @new_bcd;
    for my $template_param (@template_params) {
        my $template_type = $template_param =~ s/box$//r;
        $context->log->debug("Template type: $template_type");
        my $templates = ref $params{$template_param} eq 'ARRAY' ? $params{$template_param} : [$params{$template_param}];
        for my $template_id (@$templates) {
            $context->log->debug("-- Template ID: $template_id");
            my $dna = Viroverse::Model::bisulfite_converted_dna->insert({
                    $template_type."_id" => $template_id,
                    scientist_id   => $scientist,
                    date_completed => $params{bisulfite_conversion_date_completed},
                    note           => $params{bisulfite_conversion_notes},
                    protocol_id    => $params{bisulfite_conversion_protocol},
            });
            push @new_bcd, $dna->give_id;
        }
    }
    $txn->commit;
    push @{$context->session->{sidebar}->{bisulfite_converted_dna}}, @new_bcd;
}

sub PCR : Local {
    my ($self, $context) = @_;

    my %to_pcr = (
        extraction => [],
        rt        => [],
        bisulfite_converted_dna => [],
    );

    $context->forward('Viroverse::Controller::sidebar','gel_sidebar_to_stash');
    $context->forward('Viroverse::Controller::sidebar','sidebar_to_stash');

    if (ref $context->stash->{extraction}) {
        @{$to_pcr{extraction}} = grep {$_->extract_type_id->name eq 'DNA'} @{$context->stash->{extraction}};
    }

    if (ref $context->stash->{rt}) {
        $to_pcr{rt} = $context->stash->{rt};
    }

    if (ref $context->stash->{bisulfite_converted_dna}) {
        $to_pcr{bisulfite_converted_dna} = $context->stash->{bisulfite_converted_dna};
    }

    unless ( @{$to_pcr{rt}} or @{$to_pcr{extraction}} or @{$to_pcr{bisulfite_converted_dna}}) {
        $context->stash->{notice} = q[Add a template from above to begin a reaction.];
    }

    $context->stash->{to_pcr} = \%to_pcr;

    $context->stash->{find_a} = [
        {name => 'extraction.dna', label => 'DNA extraction'},
        {name => 'rt_product', label => 'cDNA'},
        {name => 'pos_pcr', label => 'PCR product'},
        {name => 'sample.dna', label => 'DNA sample'},
        {name => 'bisulfite_converted_dna', label => 'Bisulfite-converted DNA'},
    ];

    $context->stash->{enzymes} = [ Viroverse::Model::enzyme->search_pcr ];
    $context->stash->{protocols} = [ $context->model('protocol')->search_by_type('pcr') ];

    $context->stash->{template} = 'PCR.tt';
}

sub pcr_add : Local {
    my ($self, $c) = @_;
    my $params = $c->req->params;

    # Translate flat form parameters into a nested data structure
    # holding round parameters and templates
    my @round_names = uniq map { m/pcr_round_\d+(\.\d+)?/; $&; }
        grep { $_ =~ /^pcr_round_/ }
        keys %$params;

    my @rounds = sort {
        ($a->{round_number} <=> $b->{round_number}) ||
            ($a->{multiplex} <=> $b->{multiplex})
    } map {
        my $prefix = $_;
        # We can't trust the `pcr_round_1_multiplex` form parameter because the
        # radio control in the round 1 widget can be flipped to "no" after
        # adding multiplex second rounds; instead parse out the multiplex round
        # identifier from the parameter names for round 2
        my ($round_number, $multiplex) = $prefix =~ /(\d+)(?:\.(\d+))?/;

        # The UI doesn't support this but let's avoid anything wacky.
        return ClientError($c,
            "Error: Multiplex PCR over more than 2 rounds is not supported")
            if defined $multiplex && $round_number != 2;

        my $primer_prefix = $prefix."_primer";
        my @primer_names = pairvalues
            pairgrep { $a =~ /^$primer_prefix/ } %$params;
        +{
            completed_date => $params->{$prefix."_completed_date"},
            enzyme_id      => $params->{$prefix."_enzyme"},
            notes          => $params->{$prefix."_notes"},
            primer_names   => \@primer_names,
            protocol_id    => $params->{$prefix."_protocol"},
            endpoint       => $params->{endpoint},
            round_number   => $round_number,
            multiplex      => $multiplex // 0,
        };
    } @round_names;

    my @template_sets = map {
            my ($type, $id, $n) = split /-/, $_;
            +{
                input_product_type => $type,
                input_product_id   => $id,
                replicates         => $params->{$type."box$id"."repl$n"},
                volume             => $params->{$type."box$id"."vol$n"},
                unit               => $params->{$type."box$id"."unit$n"},
            }
        }
        uniq map { m/^(\w+)box(\d+)\w+(\d+)/; "$1-$2-$3" }
        grep { m/^\w+box\d+\w+\d+$/}
        keys %$params;

    # We need to map these weird one-off keys from various versions of the
    # submission form to appropriate ViroDB::Result classes. I bet there's a
    # way to redesign the form and the controller to hide this elsewhere.
    my %model_for = (
        extract                 => 'Extraction',
        extraction              => 'Extraction',
        'extraction.rna'        => 'Extraction',
        'extraction.dna'        => 'Extraction',
        rt_product              => 'ReverseTranscriptionProduct',
        rt                      => 'ReverseTranscriptionProduct',
        pcr                     => 'PolymeraseChainReactionProduct',
        pos_pcr                 => 'PolymeraseChainReactionProduct',
        sample                  => 'Sample',
        bisulfite_converted_dna => 'BisulfiteConvertedDNA',
    );


    my $txn = $c->model("ViroDB")->schema->txn_scope_guard;
    my @pcr_product_ids_for_sidebar;

    my $pcr_scientist = $c->model("ViroDB::Scientist")->find({
        name => $params->{scientist_name},
    });

    # all the ClientError messages below start with "Error" so that legacy
    # frontend code will automatically display them in the page without
    # modification

    return ClientError($c, "Error: Scientist not found")
        unless $pcr_scientist;

    return ClientError($c, "Error: No replicates defined")
        unless @template_sets;

    # outer loop: each set of templates (input, volume, replicate)
    for my $template_set (@template_sets) {
        my $class = $model_for{$template_set->{input_product_type}};
        my $initial_product = $c->model("ViroDB::$class")
            ->find($template_set->{input_product_id})
            or return ClientError($c,
                sprintf "Error: Input product not found",
                    $class,
                    $template_set->{input_product_id}
            );

        my $unit = $c->model("ViroDB::Unit")->find({
            name => $template_set->{unit},
        }) or return ClientError($c, "Error: unknown unit $template_set->{unit}");

        my $round_number_increment = 0;
        if ($initial_product->isa("ViroDB::Result::PolymeraseChainReactionProduct")) {
            $round_number_increment = $initial_product->round;
        }

        # inner loop: create pcr_template and pcr_product for each round. The
        # input of the pcr_template is the initial input product for each
        # replicate of the first round, and each output product from round n
        # for round n+1
        my @input_products = ($initial_product) x $template_set->{replicates};
        for my $round (@rounds) {
            my @primers = map {
                $c->model("ViroDB::Primer")->find({ name => $_ })
                    or return ClientError($c, "Error: unknown primer $_")
            } @{ $round->{primer_names} };
            my @output_products;
            my $replicate = 1;
            for my $input_product (@input_products) {
                try {
                    my $template = $c->model("ViroDB::PolymeraseChainReactionTemplate")->create({
                        scientist      => $pcr_scientist,
                        unit           => $unit,
                        volume         => $template_set->{volume},
                        date_completed => $round->{completed_date},
                        input_product  => $input_product,
                    });
                    $template->discard_changes;
                    my $output_product = $c->model("ViroDB::PolymeraseChainReactionProduct")->create({
                        pcr_template      => $template,
                        scientist         => $pcr_scientist,
                        date_completed    => $round->{completed_date},
                        protocol_id       => $round->{protocol_id},
                        enzyme_id         => $round->{enzyme_id},
                        endpoint_dilution => $round->{endpoint},
                        notes             => $round->{notes},
                        replicate         => $replicate,
                        round             =>
                            $round->{round_number} + $round_number_increment,
                    });
                    $output_product->discard_changes;
                    $output_product->set_primers(\@primers);
                    push @output_products, $output_product;
                    push @pcr_product_ids_for_sidebar, $output_product->id;
                    $replicate++;
                } catch {
                    my $err = $_;
                    log_error {[ "Couldn't save PCR product: %s", $err ]};
                    return ServerError($c, "Error: Couldn't save PCR product");
                };
            }

            # For single-plex PCR, we conceivably can enter any number of rounds
            # at once in a single form. After each round, the output products
            # become the input products for the next round. For multiplex PCR,
            # the first-round products are used as the input to one or more
            # second rounds. The interface only allows multiplex second rounds,
            # not third or subsequent rounds, so we take it for granted that
            # when we save the results of a multiplex round any more rounds left
            # to do are using the same inputs as the one we just did (i.e.,
            # first-round products.
            @input_products = @output_products
                unless $round->{multiplex};
        }
    }


    $txn->commit;

    $c->forward('gel_add_label',['pcr',@pcr_product_ids_for_sidebar]);
    $c->forward('Viroverse::Controller::sidebar','gel_sidebar_to_stash');
    $c->forward('Viroverse::Controller::sidebar','sidebar_to_stash');
}

sub PCR_gel : Local {
    my ($self, $context) = @_;

    $context->forward('Viroverse::Controller::sidebar','sidebar_to_stash');

    $context->stash->{find_a} = [
        {name => 'pcr', label => 'PCR product'}
    ];

    $context->stash->{from} = 'PCR_gel';

    $context->forward('gel');
}


sub receive_gel : Local {
    my ($self, $context) = @_;

    my $upload = $context->request->upload('gel_file');
    my $from = $context->request->param('from');

    #TODO:scientist_id etc
    $context->detach('user_error',['no file','fh empty']) unless defined $upload;
    my $img = $upload->slurp;

    my $info = Image::Info::image_info(\$img);
    $context->log->debug(Data::Dump::dump($info));
    my $mime;
    if ($info->{file_media_type} eq "image/tiff") {
        my $convert = Imager->new;
        $convert->read(data => $img, type => "tiff")
            or die "Error reading tiff data: ", $convert->errstr;
        $convert->write(data => \$img, type => "png")
            or die "Error writing png data from tiff: ", $convert->errstr;
        $mime = "image/png";
    } elsif (none { $info->{file_media_type} eq $_ } qw(image/jpeg image/png)) {
        $context->detach('user_error', ['Unsupported image type: ' . ($info->{file_media_type} || "(unknown)")]);
    } else {
        $mime = $info->{file_media_type};
    }

    my $gel = Viroverse::Model::gel->insert({
        image=>$img, 
        mime_type => $mime,
        name => $upload->filename,
        scientist_id => $context->stash->{scientist}->scientist_id
    });

    push @{$context->session->{sidebar}->{gel}}, $gel->get('gel_id');

    $context->forward('PCR_gel');

}

sub gel_add_label : Local {
    my ($self, $context) = @_;

    #TODO: this should probbaly validate, but is pretty safe just being called with values from the product selector
    my ($key,@values) = @{$context->req->arguments};
    if ($key eq 'pcr') {
    #have to instantiate all of these to know where to put new ones...
        my @new_pcr = @values;
        push @new_pcr,@{$context->session->{sidebar}->{to_gel}->{pcr}} if $context->session->{sidebar}->{to_gel}->{pcr};
        $context->session->{sidebar}->{to_gel}->{pcr} = Viroverse::Model::pcr->organize_ids_primers(\@new_pcr);
    } else {
        push @{$context->session->{sidebar}->{to_gel}->{$key}},@values;
    }
}

sub gel : Private {
    my ($self, $context) = @_;

    $context->forward('Viroverse::Controller::sidebar','gel_sidebar_to_stash');
    $context->stash->{template} = 'gel.tt';
}

sub pos_pcr : Local {
    my ($self, $context) = @_;

    $context->forward('Viroverse::Controller::sidebar','sidebar_to_stash');

    my @found_pos_pcr;
    push @found_pos_pcr, grep { $_->is_positive } @{$context->stash->{pcr} || []};
    push @found_pos_pcr, grep { $_->is_positive } @{$context->stash->{to_gel}{pcr}}
        if $context->stash->{to_gel} and $context->stash->{to_gel}{pcr};

    push @found_pos_pcr, @{ $context->stash->{pos_pcr}  || [] };
    push @found_pos_pcr, @{ $context->stash->{pcr_pool} || [] };

    @{$context->stash->{pos_pcr}} = List::MoreUtils::uniq(@found_pos_pcr);

    unless ( @{$context->stash->{pos_pcr}} ) {
        $context->stash->{notice} = 'Need a positive PCR product to proceed';
    }

    $context->stash->{find_a} = [
        {name => 'pos_pcr', label => 'PCR product'}
    ];
    $context->stash->{"${_}_protocols"} = [ $context->model('protocol')->search_by_type($_) ]
        for qw(purification concentration);
    $context->stash->{template} = 'post_gel.tt';
}

sub pos_pcr_add : Local {
    my ($self, $context) = @_;

    my %params = %{$context->req->params};

    $context->detach('user_error',['You must select a product on which to act.']) if ! ($params{pos_pcrbox});

    my @scientists;
    if ($params{purification_kit}) {
        my %new_purif;
        my $purif_scientist_id;
        @scientists = Viroverse::Model::scientist->search({ name =>  $params{purif_scientist_name} } );
        if (@scientists == 1) {
            $new_purif{scientist_id} = $scientists[0];
        } else {
            $context->detach('user_error',["unable to resolve purification scientist name",'unable to resolve scientist '.$params{purif_scientist_name}]);
        }

        my $p_conc = $params{purif_final_conc};
        if (length($p_conc) > 0 ) {
            $context->detach('user_error',["Illegal purification final concentration"]) 
                if $p_conc !~ m/^(\d+(\.\d+)?)$|^(\.\d+)$/;
            $new_purif{final_conc} = $p_conc;
        }

        $new_purif{protocol_id} = $params{purification_kit};

        $new_purif{date_completed} = $params{purif_date};
        $context->detach('user_error',['Date is required','missing purif date']) unless $new_purif{date_completed};
        $context->detach('user_error',['Date must be in ISO format (YYYY-MM-DD)','bad purif date']) unless Viroverse::db::validate_date( $new_purif{date_completed} );

        $new_purif{notes} = $params{purif_notes};
        foreach my $pcr_product_id ($context->req->param('pos_pcrbox')) {
            $new_purif{pcr_product_id} = $pcr_product_id;
            my $new_obj = Viroverse::Model::pcr::cleanup->insert(\%new_purif);
        }
    } #end of purification

    if ($params{concentration_kit}) {
        my %new_conc;
        my $conc_scientist_id;
        @scientists = Viroverse::Model::scientist->search({ name =>  $params{conc_scientist_name} } );
        if (@scientists == 1) {
            $new_conc{scientist_id} = $scientists[0];
        } else {
            $context->detach('user_error',["unable to resolve concentration scientist name"]);
        }

        my $c_conc = $params{conc_final_conc};
        if (length($c_conc) > 0) {
            $context->detach('user_error',["Illegal concentration final result"])
                if $params{conc_final_conc} !~ m/^(\d+(\.\d+)?)$|^(\.\d+)$/;
            $new_conc{final_conc} = $params{conc_final_conc};
        }

        $new_conc{protocol_id} = $params{concentration_kit};
        $new_conc{date_completed} = $params{conc_date};
        $context->detach('user_error',['Date is required','missing conc date']) unless $new_conc{date_completed};
        $context->detach('user_error',['Date must be in ISO format (YYYY-MM-DD)','bad conc date']) unless Viroverse::db::validate_date( $new_conc{date_completed} );
        $new_conc{notes} = $params{conc_notes};
        foreach my $pcr_product_id ($context->req->param('pos_pcrbox')) {
            $new_conc{pcr_product_id} = $pcr_product_id;
            my $new_obj = Viroverse::Model::pcr::cleanup->insert(\%new_conc);
        }

    } #end of concentration

    foreach my $pcr ($context->req->param('pos_pcrbox')) {
        push @{$context->session->{sidebar}->{pcr_more}},$pcr;
    }

}

sub gel_label : Local {
    my ($self, $context) = @_;
    my @gels;
    my @ladders;
    my $i = 0;
    my @pcr_ids;
    $context->forward('Viroverse::Controller::sidebar','sidebar_to_stash');
    $context->forward('Viroverse::Controller::sidebar','gel_sidebar_to_stash');
    $context->stash->{all_ladders} = ["HindIII Ladder", "Kb Ladder",'Kb+ Ladder']; #TODO put these in db
    $context->stash->{stock_labels} = Viroverse::Model::gel_lane->stock_labels();
    if(defined($context->stash->{to_gel}->{pcr})){ # if pcr gel set up for quality and grab default ladder
        push(@pcr_ids, map{$_->pcr_product_id()} @{$context->stash->{to_gel}->{pcr}});
        my $gp = $context->stash->{to_gel}->{pcr}->[0]->genome_portion();
        if($gp == 3){
            @ladders = ("HindIII Ladder");
        }elsif($gp == 1){
            @ladders = ("kb Ladder");
        }else{
            @ladders = ("HindIII Ladder", "kb Ladder");
        }
    }
    foreach my $gel (@{$context->stash->{gel}}){
        my @tmp_lanes = $gel->lanes();
        my @lanes;
        foreach my $lane (@tmp_lanes){
            my $pos_txt;
            if(defined($lane->pcr_product_id)){
                push(@pcr_ids, $lane->pcr_product_id->pcr_product_id());
            }
            if(!defined($lane->pos_result())){
                $pos_txt = "&nbsp;";
            }elsif($lane->pos_result() == 1){
                $pos_txt = "Pos";
            }elsif($lane->pos_result() == 0){
                $pos_txt = "Neg";
            }
            push(@lanes, {
                type_id => $lane->gel_lane_id(),
                label => $lane->label(),
                print_label => $lane->print_label(),
                name => $lane->to_string(),
                pos_neg => $lane->hasPositivity(),
                pos => $pos_txt,
                product_id => $lane->product()?$lane->product->id():undef,
                nickname => $lane->product()?$lane->product->name():"",
                shorthand => $lane->shorthand(),
                dil_factor => (($lane->pcr_product_id and $lane->pcr_product_id->first_round_pcr_template)
                    ? $lane->pcr_product_id->first_round_pcr_template->volume()
                    : undef),
            });
        }
        if($i == 0){ #if first gel add new products;
            my $first_row = defined($lanes[0])?$lanes[0]->{label}:0;
            my @front_lanes;
            $i++;
            foreach my $type (sort keys(%{$context->stash->{to_gel}})){
                foreach my $product (@{$context->stash->{to_gel}{$type}}){

                    my $lane = {
                        name => $product->to_string(),
                        pos_neg => 1,
                        product_id => $product->id(),
                        type_id => $product->id(),
                        nickname => $product->name(),
                        shorthand => $product->shorthand(),
                        dil_factor => (($type eq 'pcr' and $product->first_round_pcr_template)
                            ? $product->first_round_pcr_template->volume()
                            : undef)
                    };
                    if($i < $first_row){
                        push(@front_lanes, $lane);
                    }else{
                        push(@lanes, $lane);
                    }
                    $i++;
                }
            }
            unshift(@lanes, @front_lanes);
        }
        if(scalar(@tmp_lanes) < 1){ #if no lanes associated with saved gel add default labels
            foreach (@ladders){
                unshift(@lanes, {name =>$_, shorthand => 'special_label'});
            }
            foreach(sort keys(%{$context->stash->{stock_labels}})){
                if($context->stash->{stock_labels}->{$_}->{default}){
                    push(@lanes, {name => $_, pos_neg => $context->stash->{stock_labels}->{$_}->{pos},shorthand => 'special_label'});
                }
            }

        }
        $i = 1;
        foreach(@lanes){
            $_->{label} = $i;
            $_->{print_label} = ($gel->ninety_six_well() && $i < 97)?Viroverse::Model::gel_lane->intTo96Well($_->{label}):$_->{label};
            $i++;
        }
        push(@gels, {
                gel_id => $gel->gel_id(),
                name => $gel->name(),
                scientist => $gel->scientist_id->name(),
                ninety_six_well => $gel->ninety_six_well(),
                lanes => \@lanes
                 });
    }
    if(scalar(@pcr_ids) > 0){
        my %pcr_repeats;
        my @bad_pcrs;
        foreach my $pcr_id (@pcr_ids) {
            if (!exists($pcr_repeats{$pcr_id}))  {
            # First time we've seen this one
            $pcr_repeats{$pcr_id} = 0
            } elsif ($pcr_repeats{$pcr_id}) {
            # We've seen this one before and reported
            $pcr_repeats{$pcr_id}++
            } else {
            # Second time, so report the duplicate
            push(@bad_pcrs, $pcr_id);
            $pcr_repeats{$pcr_id} = 1
            }
        }
        $context->forward('Viroverse::Controller::input::pcr', 'groupPCRs4Qual', [\@pcr_ids]);
        my %q_res = %{$context->stash->{quality}};
        foreach my $q_key (keys(%q_res)){
            my @pcrs = @{$q_res{$q_key}->{pcrs}};
            my $pcr_check = 0;
            map {$pcr_check += $pcr_repeats{$_->pcr_product_id }} @pcrs;
            if($pcr_check > 0){  # same pcr product loaded more than once;
                $context->stash->{rm_from_quality}->{$q_key} = $q_res{$q_key};
            }
        }
    }


    $context->stash->{gels} = \@gels;

    $context->stash->{controls} = {'pos. control' => 1, 'neg. control' => 1};
    $context->stash->{template} = 'gel_label.tt';
}

sub attach_gel_labels : Local {
    my ($self, $context) = @_;
    my %params = %{$context->req->parameters};

    my @all_lanes = grep { /-wellnum$/ } keys %params;
    my @quality = grep { /-q$/ } keys %params;
    my @labels = grep {/^label-/ } keys %params;
    my @ninety_six_well = grep { /_96well$/ } keys %params;
    my %dropped;
    my @gel_lanes;
    my %lane2id;
    my @pos_pcr;

    Viroverse::CDBI->db_Main->begin_work;

    foreach my $label (@labels) {
        #like label_3_1_mw or label_4_7_pcr_
        my ($count,$type,$id) = (split /-/,$label)[1..3];
        my ($dropped_gel_id,$pos_x,$pos_y) = $params{$label} =~ m/gel_(\d+)=(\d+),(-?\d+)$/;
        $pos_x = 0 if $pos_x <0;
        $pos_y = 0 if $pos_y <0;

        my ($pcr_id,$name);
        if ($type eq 'special_label') {
            $name = $context->session->{sidebar}->{to_gel}->{special_label}->[$id]->{name};
        } elsif ($type eq 'pcr') {
            $pcr_id = $id;
        } else {
            $context->detach('mk_error',["what is $type?"]);
        }

        my $positivity = $params{ join('-',$count,$type,$id,'pos') };
        my $lane = $params{ join('-',$count,$type,$id,'wellnum') };
        my $pos = Viroverse::Model::gel_lane->pos_decode($positivity);

        my $new_label = Viroverse::Model::gel_lane->insert({
            gel_id => $dropped_gel_id,
            pcr_product_id => $pcr_id,
            loc_x => $pos_x,
            loc_y => $pos_y,
            label => $lane,
            name => $name,
            pos_result => $pos
        });


        $dropped{type}->{$id} = 1;

    }

    foreach (@ninety_six_well){
        my $gel_id = (split(/-/, $_))[0];
        my $gel = Viroverse::Model::gel->retrieve($gel_id);
        $gel->set("ninety_six_well" => $params{$_});
    }

    my $gel;
    foreach my $label (@all_lanes) {
        my ($gel,$count,$type,$id) = (split /-/, $label)[0..3];
        next if $dropped{type}->{$id};

        my $positivity = $params{join('-',$gel,$count,$type,$id,'pos') };

        my $lane = $params{$label};

         if ($type eq 'special_label') {
            #if name submitted via form use that otherwise look it up from sidebar.
            my $name = $params{join('-',$gel, $count,$type,$id,'label_name')};
            my $new_label = Viroverse::Model::gel_lane->insert({
                gel_id => $gel,
                label => $lane,
                name => $name,
                pos_result => Viroverse::Model::gel_lane->pos_decode($positivity)
            });
        }elsif($type eq 'gel_lane'){
            my $gel_lane = Viroverse::Model::gel_lane->retrieve($id);
            $gel_lane->set(
                    label => $lane,
                    pos_result => Viroverse::Model::gel_lane->pos_decode($positivity),
                );
            if(defined($gel_lane->pcr_product_id())){
                $lane2id{$gel_lane->pcr_product_id()->pcr_product_id()} = $id;
            }

        }elsif ( $type eq 'pcr' ) {
            my $pos_neg = Viroverse::Model::gel_lane->pos_decode($positivity);
            my $product_model = 'Viroverse::Model::' . $type;
            my $product = $product_model->retrieve($id);
            my $product_key = $product->columns('Primary')->{name};
            my $new_label = Viroverse::Model::gel_lane->insert({
                                        gel_id => $gel,
                                        label => $lane,
                                        pos_result => $pos_neg,
                                        $product_key => $id,
                                    });
            $lane2id{$id} = $new_label->gel_lane_id();
            if ($type eq 'pcr' && $pos_neg) {
                push (@pos_pcr, $id);
            }
        } else {
            $context->detach('mk_error',["Product $type is currently not supported!"])
        }

    }

    foreach my $name_param (grep {/-rename$/ } keys %params) {
        my $new_name = $params{$name_param};

        # Indexes offset +1 from HTML because JS prepends another id on submit.
        my ($type,$id) = (split /-/,$name_param)[2,3];

        my $pcr;
        if ($type eq 'pcr') {
            $pcr = Viroverse::Model::pcr->retrieve($id)
                or return $context->detach('mk_error',["Can't find PCR $id"]);
        }
        elsif ($type eq 'gel_lane') {
            my $gl = Viroverse::Model::gel_lane->retrieve($id);
            $pcr = $gl->pcr_product_id;
        }

        # XXX TODO: Only PCR for now
        next unless $pcr;

        # Set PCR name if we have a new name or we're removing an existing name.
        next unless length $new_name
                 or length $pcr->name;
        $pcr->set( name => $new_name );
    }
    foreach my $q (@quality){
        if($params{$q} eq "yes"){
            $q =~ s/-q$//;
            my @pcrs = lc(ref($params{$q. "_pcr"})) eq "array"?@{$params{$q. "_pcr"}}:($params{$q. "_pcr"});
            map{push(@gel_lanes, $lane2id{$_})} @pcrs;
        }
    }

    Viroverse::CDBI->db_Main->commit;

    @pos_pcr = @{ Viroverse::Model::pcr->organize_ids_primers(\@pos_pcr) }; #put pos_pcr in proper order needs to go after commit
    $context->session->{sidebar}->{pos_pcr} = \@pos_pcr;
    if(scalar(@gel_lanes) > 0){
        $context->forward('Viroverse::Controller::input::pcr', 'calc_copy_number', [\@gel_lanes, 1]);
        $context->session->{sidebar}->{quality} = $context->stash->{quality};
        $context->{response}->{body} = 'OK,/input/pcr/showCopyNumResults/';

    }else{
        $context->{response}->{body} = 'OK,/input/pos_pcr/';
    }
}

=head1 AUTHORS

Wenjie Deng and Brandon Maust

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
