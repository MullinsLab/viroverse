package Viroverse::Model::pcr;
use Moo;
BEGIN { extends 'Viroverse::CDBI' };

use strict;
use warnings;

use Carp qw[croak];
use Viroverse::Model::rt;
use Viroverse::Model::gel;
use Sort::Naturally qw< ncmp >;
use Physics::Unit::Scalar qw< ScalarFactory >;

with 'Viroverse::Model::enumerable';

__PACKAGE__->table('viroserve.pcr_product');
__PACKAGE__->sequence('viroserve.pcr_product_pcr_product_id_seq');
__PACKAGE__->columns(Essential => qw[
    pcr_product_id
    round
    replicate
    name
    successful
    protocol_id
    date_completed
    date_entered
    notes
    pcr_template_id
    hot_start
    endpoint_dilution
    genome_portion
    reamp_round
    vv_uid
    scientist_id
    pcr_pool_id
    enzyme_id
]);

__PACKAGE__->has_a(scientist_id => 'Viroverse::Model::scientist');

__PACKAGE__->has_many(primers => ['Viroverse::Model::pcr_primer', 'primer_id']);

around 'primers' => sub {
    my $orig = shift;
    my $self = shift;
    if ($self->pcr_pool_id) {
        return sort $self->pcr_pool_id->primers(@_);
    }
    return sort $self->$orig(@_);
};

__PACKAGE__->has_many(cleanups => 'Viroverse::Model::pcr::cleanup','pcr_product_id');
__PACKAGE__->has_many(sequences => 'Viroverse::Model::sequence::dna', 'pcr_product_id');
__PACKAGE__->has_many(gel_lanes => 'Viroverse::Model::gel_lane');
__PACKAGE__->has_a(pcr_template_id => 'Viroverse::Model::pcr_template');
__PACKAGE__->has_a(pcr_pool_id => 'Viroverse::Model::pcr_pool');
__PACKAGE__->has_a(enzyme_id => 'Viroverse::Model::enzyme');

sub is_positive {
    my $self = shift;

    foreach ($self->gel_lanes) {
        return 1 if $_->pos_result;
    }
        return 0;

}

sub to_string {
    my $self = shift;

    my $name = $self->is_positive ? '+' : '';
    if ($self->reamp_round) {
        $name .= $self->pcr_template_id->to_string;
        $name .= ' reamp '.$self->reamp_round." ";
        $name .= ' repl '.$self->replicate if defined $self->replicate;
    } elsif ($self->pcr_pool_id) {
        $name .= 'pool of ';
        my @anc = $self->pcr_pool_id->pcr_products();
        $name .= $anc[0]->pcr_product_id->pcr_template_id->to_string;
        $name .= ' rnd '.$anc[0]->pcr_product_id->round;
        $name .= " (".$self->primer_strings.") ";
        $name .= " with ".$self->enzyme_id->name." " if $self->enzyme_id;
        if (my $rr = $anc[0]->pcr_product_id->reamp_round) {
            $name .= ' re-ampl '.$rr;
            $name .= ' repls '.(join ',',sort map {$_->pcr_product_id->replicate} @anc);
        } else {
            $name .= ' repls '.(join ',',sort map {$_->pcr_product_id->replicate} @anc);
        }
    } else {
        $name .= $self->pcr_template_id ? $self->pcr_template_id->to_string : '';
        $name .= " rnd ".$self->round;
        $name .= " (".$self->primer_strings.") ";
        $name .= ' repl '.$self->replicate if defined $self->replicate;
        $name .= ' EPD' if $self->endpoint_dilution;
    }

    $name .= ' '.$self->pcr_product_id.' ';
    $name .= join(" ", map {$_->to_string} $self->cleanups);
    return $name;
}

sub longhand {
    my $self = shift;
    my $shorthand = $self->SUPER::longhand();
    if($self->is_positive()){
        return "$shorthand.pos";
    }
    return $shorthand;
}

sub primer_strings {
    my $self = shift;

    return join ", ", map {$_->name} $self->primers;
}

=head2 primers_with_proper_positions

Returns a list of hashrefs where C<primer> is the forward or reverse primer for
this amplification and C<position> is a single
L<ViroDB::Result::PrimerPosition> for that primer. The positions are selected
such that the pair of positions should delimit the amplicon being sequenced. If
a paired forward and reverse position are not found, just return all the
positions so the consumer can decide what it all means.

=cut

sub primers_with_proper_positions {
    my $self = shift;
    if ($self->pcr_pool_id) {
        return $self->pcr_pool_id->primers_with_proper_positions;
    }
    my @positions =
       sort { $a->{position}->hxb2_start <=> $b->{position}->hxb2_start }
        map {
            my $primer = $_;
            map { +{ primer => $primer, position => $_ } }
                $primer->positions
        } $self->primers;

    my @pair;
    for (@positions) {
        if (not @pair and $_->{primer}->orientation eq "F") {
            push @pair, $_;
        }
        elsif (@pair and $_->{primer}->orientation eq "R") {
            push @pair, $_;
            last;
        }
    }
    return @pair == 2 ? \@pair : \@positions;
}

sub input_product { $_[0]->pcr_template_id };
with 'Viroverse::Model::Role::MolecularProduct';

# Override the 'parent' method from the MolecularProduct role, because we want
# to avoid including PCR templates in derivation-like contexts. In the final
# analysis, pcr_template records are more or less in a 1:1 correspondence with
# pcr_product records, and just hold additional metadata about a single PCR
# reaction. They aren't "parents" or "precursors" in any relevant sense. We
# could perhaps change input_product above to return
# pcr_template_id->input_product and thereby skip _this_ override, but that's a
# little further afield from the task at hand and would require some
# double-checking of what input_product is used for. -- silby@ 2017-01-14
sub parent { $_[0]->input_product ? $_[0]->input_product->input_product : undef };

sub sample_id {
    my $self = shift;
    return $self->pcr_template_id
        ? $self->pcr_template_id->input_sample
        : undef;
}

=head2 plasmaVLcopies

Returns the number of copies of virus in the initial template based on plasma
viral load.

=cut

sub plasmaVLcopies {
    my $self = shift;
    my $clinical_vl = $self->sample_id
                    && $self->sample_id->visit
                    && $self->sample_id->visit->best_viral_load;
    return unless $clinical_vl;

    my $template = $self->first_round_pcr_template
        or return;

    if ($template->rt_product_id) {
        my $vol_cDNA   = $template->volume_with_unit;
        my $extraction = $template->rt_product_id->extraction_id;
        # The previous hardcoded assumed ratio of RNA:cDNA was 25/52.25; falling back
        # to that to preserve previous behavior when the ratio isn't present for new
        # input or backfill
        my $rna_to_cdna_ratio = $template->rt_product_id->rna_to_cdna_ratio || "25/52.25";
        my $eluted_vol = $extraction->eluted_vol_with_unit
            or return;
        my $v_plasma;
        if($extraction->unit_id->as_physics_unit->type eq "Mass") {
            my $conc = $extraction->concentration_with_unit
                or return;
            $v_plasma = $extraction->amount_with_unit->divide($conc);
        } elsif ($extraction->unit_id->as_physics_unit->type eq "Volume") {
            $v_plasma = $extraction->amount_with_unit;
        } else {
            return;
        }
        my $clinical_vl_units = ScalarFactory($clinical_vl->viral_load . " copies/ml");

        #   (clinical VL in copies/ml of plasma)
        # * (plasma volume / assumed eluted volume of extraction)
        # * (RNA / cDNA ratio)
        # * cDNA input volume (pcr template)
        # = copies per ul of initial template (actually dimensionless)
        my $plasma_density = $v_plasma->divide($eluted_vol);
        my $ratio_scalar = ScalarFactory($rna_to_cdna_ratio);
        my $copy_quotient = $clinical_vl_units->times($plasma_density)->times($ratio_scalar)->times($vol_cDNA);
        return sprintf("%.2f",$copy_quotient->convert("1"));
    } else {
        warn "plasmaVLcopies only valid for PCR from cDNA";
    }
    return;
}


=item qualityVLcopies
  Retrieves the number of copies of virus in the template based on the Quality analysis program
=cut
sub qualityVLcopies {
    my $self = shift;
    my @qual_res = $self->copyNumberResults();
    my $num_copies;
    if(ref($qual_res[0]) eq "Viroverse::Model::copy_number" and $self->first_round_pcr_template){
        $num_copies = $qual_res[0]->value * $self->first_round_pcr_template->volume();
    }

    if(defined($num_copies)){
        return sprintf("%.2f", $num_copies);
    }else{
        return "";
    }


}

=item copyNumberResults
    return all quality copy number results for this pcr's 1st round template/primers/enzymes
=cut
sub copyNumberResults {
    my $self = shift;
    return Viroverse::Model::copy_number->fetchFromPCR($self);
}

sub give_id {
    my $self = shift;
    return $self->pcr_product_id;
}

=head2 search_sample_products

Takes two hashrefs of L<SQL::Abstract> C<WHERE> criteria limiting a query which
finds PCR products based on sample criteria.  The first hashref is used to
specify criteria applicable to the C<sample> table and C<sample_patient_date> view.
The second hashref should specify criteria on the C<pcr_product> table.

Returns a list L<Viroverse::Model::pcr>.

=cut

# This duplicates some of the recursive and joining logic in
# schema/deploy/view/patient_visit_sample_pcr.sql.  Any refactoring of the two
# would necessarily remove the SQL insertion we use here to an outer query,
# leaving some common inner query.  However, that will slow the query down
# since Pg (because of guarantees it makes) can't easily push constraints down
# into the WITH RECURSIVE query.  The query below benefits from that as it
# reduces the rows in play at the start of the iteration cycle.
# -trs, 11 Jan 2016
__PACKAGE__->set_sql( _sample_products => <<'SQL' );
    WITH RECURSIVE all_pcr_products(__ESSENTIAL__, sample_id) AS (
        SELECT __ESSENTIAL(pcr_product)__, sample.sample_id
          FROM viroserve.pcr_product
          JOIN viroserve.pcr_template USING (pcr_template_id)
     LEFT JOIN viroserve.bisulfite_converted_dna ON (bisulfite_converted_dna.bisulfite_converted_dna_id = pcr_template.bisulfite_converted_dna_id)
     LEFT JOIN viroserve.rt_product      ON (rt_product.rt_product_id IN (bisulfite_converted_dna.rt_product_id,  pcr_template.rt_product_id))
     LEFT JOIN viroserve.extraction      ON (extraction.extraction_id IN (bisulfite_converted_dna.extraction_id,  pcr_template.extraction_id, rt_product.extraction_id))
          JOIN viroserve.sample          ON (sample.sample_id         IN (bisulfite_converted_dna.sample_id, extraction.sample_id, pcr_template.sample_id))
          JOIN viroserve.sample_patient_date patient ON (sample.sample_id = patient.sample_id)
               %s   -- WHERE (sample)
        UNION
        SELECT __ESSENTIAL(child)__, NULL sample_id
          FROM all_pcr_products
          JOIN (     viroserve.pcr_template
                JOIN viroserve.pcr_product  AS child USING (pcr_template_id))
            ON (all_pcr_products.pcr_product_id = pcr_template.pcr_product_id)
    )
    SELECT __ESSENTIAL__, sample_id
      FROM all_pcr_products
           %s   -- WHERE (PCR)
SQL

# Currently only used by Controller::enum->find_generic, with these possible
# columns in the criteria hashes:
#
#   sample.name
#   patient.patient_id
#
#   pcr_template_id
#   pcr_product.scientist_id
#   pcr_product.date_completed
#   pcr_product.round
#   pcr_pool_id
#   purified (not supported by this query currently, see 04c395b)
#   name
#
sub search_sample_products {
    my ($self, $sample_crit, $pcr_crit) = @_;

    my $sql = SQL::Abstract->new;
    my ($sample_where, @sample_bind) = $sql->where($sample_crit);
    my ($pcr_where,    @pcr_bind)    = $sql->where($pcr_crit);

    # Template our SQL above into a DBI statement handle
    my $sth  = $self->sql__sample_products($sample_where, $pcr_where);
    my @bind = (@sample_bind, @pcr_bind);

    # Class::DBI provides a handy convenience method to execute the statement
    # and instantiate the objects.
    return $self->sth_to_objects($sth, \@bind);
}

=item fetchByCleanedStatus
selects PCR products based on passed criteria (when cleaned or not is included)
=cut

sub fetchByCleanedStatus {
    my ($pkg, $search_ref) = @_;

    croak "fetchByCleanedStatus called improperly" unless ref $search_ref eq 'HASH';
    my $sqla = SQL::Abstract->new;

    my $purif_protocol_ids_ref = [ map {$_->give_id} Viroverse::Model::protocol->search_by_type('purification') ];


    my $cols = join ',',( map {$pkg->table.'.'.$_} $pkg->columns('Essential'),$pkg->columns('Other') );

    $search_ref->{'pcr_cleanup.protocol_id'} = $search_ref->{purified} ? $purif_protocol_ids_ref : undef ;
    delete $search_ref->{purified};

    my $sql = "SELECT distinct $cols FROM ".$pkg->table.' LEFT JOIN '. Viroverse::Model::pcr::cleanup->table.' USING (pcr_product_id) ';

    my ($where,@binds) = $sqla->where($search_ref);

    my $res_ref = $pkg->db_Main->selectall_arrayref($sql.$where,{Slice => {}},@binds);
    return ( map { $pkg->construct($_) } @{$res_ref} );
}

=item fetchFromPoolID
 Not sure this will last but for the time being a pool needs to be described by it's corresponding pcr_product
 And this seems to be a better idea than adding a might have statement to pcr_pool
=cut
sub fetchFromPoolID{
       my ($pack, $pcr_pool_id) = @_;
       my $session = Viroverse::session->new(__PACKAGE__->db_Main);
       my $sql = qq[ SELECT * FROM viroserve.pcr_product WHERE pcr_pool_id = ?];
       my $st =$session->{'dbr'}->prepare($sql);
       $st->execute(($pcr_pool_id));
       my $results_r = $st->fetchall_arrayref({});
       if(defined($results_r->[0])){ #just in case
            return Viroverse::Model::pcr->construct($results_r->[0]);
       }
       return undef;
}


=item fetchAntecedents
takes an array_ref of pcr_product_ids and returns an array_ref of hash_refs for each pcr_product that came before
each supplied product_id.  Use $row->{start_pcr} to associate a row with a supplied pcr_product_id
level is 0 for starting pcr and increments for each join required to reach a row
=cut
sub fetchAntecedents {
    my ($pkg, $pcr_id_ref) = @_;
    if (ref $pcr_id_ref ne 'ARRAY') {
        croak 'Illegal argument, need an array ref';
    }
    my @pcr_ids = @{$pcr_id_ref};

    if (@pcr_ids <1) {
        warn "No IDs passed, returning empty array";
        return [];
    }

    # XXX TODO SQL: This is terrible and part of the mess of
    # related-but-not-identical queries around PCR ancestry and descendants.
    # -trs, 8 Jan 2016
    return __PACKAGE__->db_Main->selectall_arrayref(
        q[
            WITH RECURSIVE pcr_product_parents( pcr_product_id, start_pcr, round, replicate, reamp_round, volume, pcr_template_id, template_pcr_product_id, bisulfite_converted_dna_id, rt_product_id, extraction_id, sample_id, primers, level) AS (
                 SELECT
                    pcr_product.pcr_product_id, pcr_product.pcr_product_id as start_pcr, pcr_product.round, pcr_product.replicate, reamp_round, volume, pcr_product.pcr_template_id, pcr_template.pcr_product_id, pcr_template.bisulfite_converted_dna_id, pcr_template.rt_product_id, pcr_template.extraction_id, pcr_template.sample_id, array_agg(primer.name) as primers, 0 as level
                  FROM viroserve.pcr_product JOIN viroserve.pcr_template USING (pcr_template_id) LEFT JOIN viroserve.pcr_product_primer ON (pcr_product.pcr_product_id = pcr_product_primer.pcr_product_id) LEFT JOIN viroserve.primer using (primer_id)
                 WHERE pcr_product.pcr_product_id IN( ].
          join(',', map { '?' } @pcr_ids).
                q[ )
                GROUP BY pcr_product.pcr_product_id, pcr_product.round, pcr_product.replicate, reamp_round, volume, pcr_product.pcr_template_id, pcr_template.pcr_product_id, pcr_template.bisulfite_converted_dna_id, pcr_template.rt_product_id, pcr_template.extraction_id, pcr_template.sample_id
             UNION ALL
                 SELECT
                    parent.pcr_product_id, start_pcr, parent.round, parent.replicate, parent.reamp_round, parent_template.volume, parent.pcr_template_id, parent_template.pcr_product_id, parent_template.bisulfite_converted_dna_id, parent_template.rt_product_id, parent_template.extraction_id, parent_template.sample_id, primers, level +1
                 FROM pcr_product_parents JOIN (
                        viroserve.pcr_template JOIN viroserve.pcr_product as parent USING (pcr_product_id) JOIN viroserve.pcr_template as parent_template ON (parent.pcr_template_id = parent_template.pcr_template_id)
                    ) ON (pcr_product_parents.pcr_template_id = pcr_template.pcr_template_id)
            )
            SELECT *
            FROM pcr_product_parents
            ORDER BY level desc
        ],
        { Slice => {} }, #format as array of hashrefs
        @pcr_ids
        );


}

sub fetchDescendents {
    my ($pkg, $pcr_id_ref) = @_;
    if (ref $pcr_id_ref ne 'ARRAY') {
        croak 'Illegal argument, need an array ref';
    }
    warn my @pcr_ids = @{$pcr_id_ref};

    # XXX TODO SQL: This is terrible and part of the mess of
    # related-but-not-identical queries around PCR ancestry and descendants.
    # -trs, 8 Jan 2016
    return __PACKAGE__->db_Main->selectall_arrayref(
        q[
        WITH RECURSIVE pcr_product_parents( pcr_product_id, start_pcr, round, replicate, reamp_round, volume, pcr_template_id, template_pcr_product_id, bisulfite_converted_dna_id, rt_product_id, extraction_id, sample_id, primers, level) AS (
          SELECT
            pcr_product.pcr_product_id, pcr_product.pcr_product_id as start_pcr, pcr_product.round, pcr_product.replicate, reamp_round, volume, pcr_product.pcr_template_id, pcr_template.pcr_product_id, pcr_template.bisulfite_converted_dna_id, pcr_template.rt_product_id, pcr_template.extraction_id, pcr_template.sample_id, array_agg(primer.name) as primers, 0 as level
           FROM viroserve.pcr_product JOIN viroserve.pcr_template USING (pcr_template_id) LEFT JOIN viroserve.pcr_product_primer ON (pcr_product.pcr_product_id = pcr_product_primer.pcr_product_id) LEFT JOIN viroserve.primer using (primer_id)
             WHERE pcr_product.pcr_product_id IN(].
          join(',', map { '?' } @pcr_ids).
            q[) GROUP BY pcr_product.pcr_product_id, pcr_product.round, pcr_product.replicate, reamp_round, volume, pcr_product.pcr_template_id, pcr_template.pcr_product_id, pcr_template.bisulfite_converted_dna_id, pcr_template.rt_product_id, pcr_template.extraction_id, pcr_template.sample_id
       UNION ALL
          SELECT
            child.pcr_product_id, start_pcr, child.round, child.replicate, child.reamp_round, child_template.volume, child.pcr_template_id, child_template.pcr_product_id, child_template.bisulfite_converted_dna_id, child_template.rt_product_id, child_template.extraction_id, child_template.sample_id, primers, level -1
          FROM pcr_product_parents JOIN (
                    viroserve.pcr_template child_template JOIN viroserve.pcr_product as child USING (pcr_template_id)
            ) ON (pcr_product_parents.pcr_product_id = child_template.pcr_product_id)
      )
      SELECT *
      FROM pcr_product_parents
        ORDER BY level desc
        ],
        { Slice => {} }, #fetch back as an array of hashrefs
        @pcr_ids
    );


}

sub organize_ids_primers {
    my ($pkg, $ids) = @_;
    my %primer_products;

    foreach my $pcr ( $pkg->retrieve_many(@{$ids}) ){
        my $s = lc join '.', map {$_->name} sort {$a->primer_id <=> $b->primer_id} $pcr->primers;
        push @{$primer_products{ $s }}, [
            $pcr,
            $pcr->to_string,
            ($pcr->first_round_pcr_template
                ? $pcr->first_round_pcr_template->volume
                : 0),
            $pcr->replicate,
        ];
    }

    # Group and sort by primer names
    # ... then sort by volume (descending)
    # ... then replicate number
    # ... and finally fallback to a "natural" sort by the description
    return [
        map { $_->[0]->give_id }
        map {
            sort {
                   ($b->[-2] <=> $a->[-2])
                or ($a->[-1] <=> $b->[-1])
                or ncmp($a->[1], $b->[1])
            }
            @{ $primer_products{$_} }
        }
        sort { $a cmp $b } # primers
        keys %primer_products
    ];
}

#note: makes sql calls = round number x 2
sub first_round_pcr_template {
    my $self = shift;
    croak 'instance method!' unless ref $self eq __PACKAGE__;

    unless ($self->{__first_round_pcr_template}) {
        my $t = $self->pcr_template_id;
        while ($t and $t->pcr_product_id) {
            $t = $t->pcr_product_id->pcr_template_id;
        }
        $self->{__first_round_pcr_template} = $t;
    }
    return $self->{__first_round_pcr_template};
}

sub edit_related_pcr_nicks {
    my ($pkg_or_obj, $something, $data_ref) = @_;

    my $pcr;
    if (ref $pkg_or_obj) { #called on an existing obj
        $pcr = $pkg_or_obj;
    } else { #called on insert, meaningless since you can't have descendents until after you are created
        return;
    }
    my $before_ref = __PACKAGE__->fetchAntecedents([$pcr->pcr_product_id]);
    my $after_ref  = __PACKAGE__->fetchDescendents([$pcr->pcr_product_id]);

    my @all_to_edit = map {$_->{pcr_product_id}} (@{$before_ref},@{$after_ref}); #includes actual product edited 2x, eh...

    my $edits = __PACKAGE__->db_Main->do(q[
        UPDATE viroserve.pcr_product set name = ? where pcr_product_id in (].
        (join ',', map {'?'} @all_to_edit).
        q[)],
        undef,
        $data_ref->{name},@all_to_edit
    );
    if ($edits ) {
        return 1;
    }
}

__PACKAGE__->add_trigger('before_set_name',\&edit_related_pcr_nicks);

__PACKAGE__->add_trigger('before_create', sub {
    my ($obj, $something,$data) = @_;

    my $t;
    my $_t = $obj->_attrs('pcr_template_id');
    if (ref $_t) {
        $t = $_t;
    } else {
        $t = Viroverse::Model::pcr_template->retrieve($_t);
    }

    if ($t && $t->pcr_product_id) {
            $obj->_attribute_set(name => $t->pcr_product_id->name);
    }

});

=head2 auto_nickname

A fallback identifying the round and replicate of a PCR product.
Matches the C<nick_auto> element formatted by the product finder.

=cut

sub auto_nickname {
    my $self = shift;
    return "pool" if defined $self->pcr_pool_id;
    return join "", "r", $self->round, "x", $self->replicate;
}

sub TO_JSON {
    my $self = shift;

    return {
        id=> $self->give_id,
        name=> $self->to_string,
        nickname => $self->name,
        completed=> $self->date_completed,
        scientist_name=> $self->scientist_id->name,
        sample_name => $self->sample_id->to_string,
        round => $self->round,
        reamp => $self->reamp_round,
        replicate => $self->replicate,
        primers => $self->primer_strings,
        is_pool => defined $self->pcr_pool_id ? 1 : 0
    };
}

1;
