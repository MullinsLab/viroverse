package Viroverse::Controller::enum;

use strict;
use warnings;
use base 'Viroverse::Controller';
use Viroverse::session;
use Viroverse::patient;
use Viroverse::sample;
use Viroverse::Model::sample;
use Viroverse::Model::extraction;
use Viroverse::Model::rt;
use Viroverse::Model::pcr;
use Viroverse::Model::clone;
use ViroDB::ResultSet::SampleSearch;
use EpitopeDB::peptide;
use Viroverse::Date;

use Catalyst::ResponseHelpers qw< :helpers :status >;

=head1 NAME

Viroverse::Controller::enum - Catalyst Controller

=head1 SYNOPSIS

See L<Viroverse>

=head1 DESCRIPTION

Catalyst Controller to provide JSON objects of lists of VV objects.

=head1 METHODS

=cut

sub default : Private {
    my ( $self, $c ) = @_;

    $c->response->body(q[Viroverse::Controller::enum requires parameters.  See the man page if you're confused]);
}

=head2 Patient

=cut

sub patients : Local {
    my ( $self, $context) = @_;

    my @args = @{$context->request->arguments};


    my $cohort_id = shift @args;
    my $patient_start = shift @args;

    $context->stash->{'jsonify'} = Viroverse::patient::cohort_patients($context->stash->{session},$cohort_id,$patient_start);

    $context->forward('Viroverse::View::JSON');
}

sub patients_y : Local {
    my ( $self, $context) = @_;

    my $cohort_id = $context->req->param('cohort');;
    my $patient_start = $context->req->param('query');

    my @list = Viroverse::patient::list($context->stash->{session},$cohort_id,$patient_start);
    $context->stash->{'jsonify'} = \@list;

    $context->forward('Viroverse::View::JSON','y');
}

sub scientists_y : Local {
    my ($self,$context) = @_;

    my $start = $context->req->param('query') || (@{$context->request->arguments})[0];

    my @list = Viroverse::Model::scientist->list($start);
    $context->stash->{'jsonify'} = \@list;

    $context->forward('Viroverse::View::JSON','y');
}

sub find_generic : Local {
    my ($self, $context) = @_;
    my $param = $context->request->parameters;
    my @objs;

    # Leading and trailing space should not be significant
    s/^\s+|\s+$//g for grep { defined and length } values %$param;

    for my $date (qw( date_completed date )) {
        next unless $param->{$date};

        my ($op, $iso) = Viroverse::Date->parse_with_op($param->{$date});
        if ( $iso and $op ) {
            $param->{$date} = { $op => $iso };
        } else {
            $context->detach('user_error',["Unknown date \"$param->{$date}\".  Please use YYYY-MM-DD or mm/dd/yy.","bad date to enum"]);
        }
    }

    my $type;
    if (! ($type = $param->{'find_a'} ) ) {
        $context->detach('mk_error',['No type specified'])
    }

    my $model;
    if ($type =~ m/^sample(\.[dr]na)?/) {
        $model = $context->model("ViroDB::SampleSearch");
    } else {
        $model = Viroverse::Controller::need->which_package($type)
            or return $context->detach('mk_error', ["Unknown type: <$type>"]);
    }

    # We want to load up specific objects, not search
    if (my $ids = $param->{"${type}s"}) {
        $ids = ref $ids ? $ids : [$ids];
        return $context->detach( fetch_generic => [$type, @$ids] );
    }

    # Translate cohort/id to internal patient_id if necessary
    delete $param->{patient_id}
        unless ($param->{patient_id} || '') =~ /\S/;
    if (not $param->{patient_id} and $param->{ext_pat_id} and $param->{cohort_id}) {
        $context->log->debug("looking up external patient id/cohort: <$param->{ext_pat_id}>/<$param->{cohort_id}>");
        my $pat = Viroverse::patient::get($context->stash->{session}, $param->{ext_pat_id}, { cohort_id => $param->{cohort_id} })
            or return $context->detach(
                'user_error',
                [ "Unknown patient/cohort combination.  Please use the autocomplete.",
                  "unknown cohort/patient: <$param->{cohort_id}>/<$param->{ext_pat_id}>" ],
            );
        $context->log->debug("using patient_id = ".$pat->give_id);
        $param->{patient_id} = $pat->give_id;
    }

    my %search;

    # Handle filtering by nucleic acid type
    if ($type =~ s/\.([rd]na)$//i) {
        $search{na_type} = $1;
    }

    # Universal search fields
    if ( my $sci_name = $param->{'scientist_name'} ) {
        my $sci_id = Viroverse::db::resolve_external_property($context->stash->{session}, 'scientist', $sci_name);
        $search{scientist_id} = $sci_id;
    }

    $search{name} = { ILIKE => "%$param->{name}%" }
        if grep { defined and length } $param->{name};

    $search{$model->primary_column} = delete $param->{id}
        if grep { defined and length } $param->{id};

    # special search parameters
    if ($type eq 'sample' || $type eq 'extraction') {
        my %column_of = (
                date => 'visit_date',
                tissue_type_id => 'tissue_type_id',
                patient_id => 'patient_id',
                cohort_id => 'cohort_id',
                extraction_id => 'extraction_id'
        );
        foreach my $field (keys %column_of) {
            $search{ $column_of{$field} } = $param->{$field} if (defined $param->{$field} && length($param->{$field}) > 0);
        }
        $search{'name'} = delete $search{name}
            if $search{name};

    } elsif ($type eq 'pcr' || $type eq 'pos_pcr') {
        $search{pcr_template_id} = \$Viroverse::CDBI::is_not_null;
        my %sample_search;
        $search{'pcr_product.scientist_id'} = delete $search{'scientist_id'}
            if $search{'scientist_id'};

        $search{'pcr_product.date_completed'} = $param->{date_completed} if $param->{date_completed};
        if (my $rnd = $param->{'pcr_round'} ) {
            $search{round} = $rnd;
        }

        if (my $sample_name = $param->{'sample_name'} ) {
           $sample_search{'sample.name'} = { ILIKE => "%$sample_name%" };
        }

        if (my $pcr_name = $param->{'pcr_name'} ) {
           $search{'pcr_product.name'} = { ILIKE => "%$pcr_name%" };
        }

        $sample_search{'patient.patient_id'} = $param->{'patient_id'}
            if $param->{'patient_id'};

        if (my $pool = $param->{'pcr_pool'} ) {
            if ($pool eq 'yes') {
                $search{pcr_pool_id} = {'!=',undef};
            } elsif ($pool eq 'no') {
                $search{pcr_pool_id} = \$Viroverse::CDBI::is_null;
            }
        }

        # XXX FIXME: This currently doesn't work when %sample_search is
        # populated (see conditional below).  Until we fix it, ignore it so we
        # don't throw errors.  When fixed, please re-enable the disabled UI
        # in prod.js as well.
        # -trs, 17 Dec 2014
        if (0) {
            my $cleaned = $param->{'pcr_cleaned'};
            if (length($cleaned) > 0) {
                $search{purified} = $cleaned;
            }
        }

        if (keys %sample_search) {
            # Clean up search fields for messy sample search SQL.  It uses WITH
            # RECURSIVE to generate an "all_pcr_products" resultset, so we need
            # to use unqualified columns.  It seems more correct to strip the
            # qualification in this case than add it for the two other cases.
            # -trs, 2013-09-30
            for my $column (grep { s/^pcr_product\.// } keys %search) {
                $context->log->warn("Search params contain both $column and pcr_product.$column; using the latter")
                    if exists $search{$column};
                $search{$column} = delete $search{"pcr_product.$column"};
            }
            @objs = Viroverse::Model::pcr->search_sample_products(\%sample_search, \%search);
        } elsif (defined $search{purified} ) {
            @objs = Viroverse::Model::pcr->fetchByCleanedStatus(\%search);
        } else {
            @objs = Viroverse::Model::pcr->search_where(\%search);
        }

        $context->stash->{jsonify} = [ map { $_->TO_JSON } @objs ];
        $context->stash->{find_a} = $param->{'find_a'};

        $context->detach('Viroverse::View::JSON','y'); #PCR is special case
    }

    $context->stash->{find_a} = $param->{'find_a'};
    $search{date_completed} = $param->{date_completed} if $param->{date_completed};
    if (!keys %search) {
        return;
    }
    %search = $model->transform_search(%search) if $model->can('transform_search') ;
    $context->stash->{jsonify} = [map { $_->TO_JSON } $model->search_where(\%search) ];
    $context->forward('Viroverse::View::JSON','y');

}

sub fetch_generic : Local {
    my ($self, $context) = @_;

    my ($type,@ids) = @{$context->req->args};
    $context->detach('mk_error',['No type specified']) unless $type;
    $context->detach('mk_error',["No id for $type"]) unless @ids;

    $context->stash->{jsonify} = [map { $_->TO_JSON } Viroverse::Controller::need->which_package($type)->retrieve_many(@ids) ];
    $context->forward('Viroverse::View::JSON','y');
}

sub samples : Local {

    my ($self,$context) = @_;
    my $patient_id;

    if (@{$context->req->arguments} == 2) {
        my $patient = Viroverse::patient::get($context->stash->{session},$context->req->arguments->[1], {cohort_id => $context->req->arguments->[0]} );
        return unless defined $patient;
        $patient_id = $patient->give_id;
    } else {
        $patient_id = shift @{$context->request->arguments};
    }

    return unless defined $patient_id;
    return if $patient_id eq 'undefined';

    my $samples_ref = Viroverse::sample::get_patient_samples($context->stash->{session},$patient_id,'ONLY_REAL');
    while (my ($sample_id,$sample_details) = each %{$samples_ref}) {
        foreach my $field (@Viroverse::sample::expand_these) {
            #TODO: move this into a proper view
            if (defined $sample_details->{$field}) {
                $sample_details->{$field} = join ",\n", grep {defined} @{ $sample_details->{$field} };
            }
        }
    }
    $context->stash->{'jsonify'} = $samples_ref;
    $context->forward('Viroverse::View::JSON');
}

sub primers_y : Local {
    my ($self,$context) = @_;
    my $start = $context->req->param('query') || (@{$context->request->arguments})[0];

    my @list = Viroverse::Model::primer->list($start);
    $context->stash->{'jsonify'} = \@list;

    $context->forward('Viroverse::View::JSON','y');

}

sub pept_names : Local {
    my ($self,$context) = @_;

    if ($context->stash->{features}->{epitopedb}) {
        my $start = (@{$context->request->arguments})[0];

        $context->stash->{'jsonify'} = EpitopeDB::peptide::list_names($start);
    }

    $context->forward('Viroverse::View::JSON');

}

sub pept_seqs : Local {
    my ($self,$context) = @_;

    my $start = (@{$context->request->arguments})[0];

    $context->stash->{'jsonify'} = EpitopeDB::peptide::list_seqs($start);

    $context->forward('Viroverse::View::JSON');

}

sub pool_names : Local {
    my ($self,$context) = @_;

    my $start = (@{$context->request->arguments})[0];

    $context->stash->{'jsonify'} = EpitopeDB::pool::list_names($start);

    $context->forward('Viroverse::View::JSON');

}

=head1 AUTHOR

Brandon Maust

=cut

1;
