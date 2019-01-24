package Viroverse::Model::copy_number;
use base 'Viroverse::CDBI';
use ViroDB;
use Viroverse::Model::copy_number_gel_lane;
use Viroverse::Model::primer;
use Viroverse::Model::enzyme;
use Carp;
use strict;

__PACKAGE__->table('viroserve.copy_number');
__PACKAGE__->columns(Essential => qw[
    copy_number_id
    rt_product_id
    extraction_id
    bisulfite_converted_dna_id
    sample_id
    value
    std_error
    vv_uid
    scientist_id
    date_created
    key
    rec_addition
    dil_table
]);
__PACKAGE__->columns(TEMP => qw[name]);

__PACKAGE__->sequence('viroserve.copy_number_copy_number_id_seq');
__PACKAGE__->has_a(rt_product_id => 'Viroverse::Model::rt');
__PACKAGE__->has_a(extraction_id => 'Viroverse::Model::extraction');
__PACKAGE__->has_a(bisulfite_converted_dna_id => 'Viroverse::Model::bisulfite_converted_dna');
__PACKAGE__->has_a(scientist_id => 'Viroverse::Model::scientist');
__PACKAGE__->has_many(gel_lanes => ['Viroverse::Model::copy_number_gel_lane','gel_lane_id']);
__PACKAGE__->has_a(
    sample_id => 'ViroDB::Result::Sample',
    inflate => sub {
        return ViroDB->instance->resultset('Sample')->find($_[0]);
    },
    deflate => 'id',
);

__PACKAGE__->set_sql( by_sample => <<'SQL' );
    SELECT __ESSENTIAL(copy_number)__
      FROM viroserve.copy_number
 LEFT JOIN viroserve.bisulfite_converted_dna USING (bisulfite_converted_dna_id)
 LEFT JOIN viroserve.rt_product ON (rt_product.rt_product_id IN (bisulfite_converted_dna.rt_product_id, copy_number.rt_product_id))
 LEFT JOIN viroserve.extraction    ON (extraction.extraction_id IN (bisulfite_converted_dna.extraction_id, rt_product.extraction_id, copy_number.extraction_id))
      JOIN viroserve.sample        ON (sample.sample_id IN (bisulfite_converted_dna.sample_id, extraction.sample_id, copy_number.sample_id))
     WHERE sample.sample_id = ?
     ORDER BY date_created DESC
SQL

sub input_product {
    my $self = shift;
    return $self->rt_product_id || $self->extraction_id || $self->sample_id;
}

sub input_sample {
    my $self  = shift;
    my $input = $self->input_product;
    return $input->isa("ViroDB::Result::Sample")
        ? $input
        : $input->sample_id;
}

sub save{
    my ($self, $template_id, $value, $std_error, $dil_table, $scientist_id, $key, $rec_addition, $gel_lane_ids) = @_;
    my @template = split(/_/, $template_id);
    my $template_key = {
        rt          => "rt_product_id",
        extraction  => "extraction_id",
        sample      => "sample_id",
        bisulfite   => "bisulfite_converted_dna_id",
    }->{ $template[0] };

    die "bad template id $template_id passed can't create new row"
        unless $template_key;

    $self->db_Main->begin_work();
    my $copy_number_row = __PACKAGE__->insert({$template_key => $template[1], value => $value, std_error => $std_error, scientist_id => $scientist_id, key => $key, rec_addition => $rec_addition, dil_table => $dil_table});
    foreach(@{$gel_lane_ids}){
        Viroverse::Model::copy_number_gel_lane->insert({copy_number_id => $copy_number_row->copy_number_id(), gel_lane_id => $_});
    }
    $self->db_Main->commit();

    return $copy_number_row;
}

sub TO_JSON {
    my $self = shift;

    return {
        copy_number_id => $self->copy_number_id(),
        rt_product_id => $self->rt_product_id(),
        extraction_id => $self->extraction_id(),
        value => $self->value(),
        std_error => $self->std_error(),
        vv_uid => $self->vv_uid(),
        scientist_id => $self->scientist_id(),
        date_created => $self->date_created(),
        key => $self->key(),
        rec_addition => $self->rec_addition(),
        dil_table => $self->dil_table(),
        name => $self->name(),
        valueToString => $self->valueToString(),
    }
}

sub toString {
    my $self = shift;
    return $self->pcr_name(). "\n"  . $self->date_created() .  "  # of copies per unit:  " . $self->value() . " +/- " . $self->std_error();
}

sub valueToString {
    my $self = shift;
    return $self->date_created() .  "  # of copies per unit:  " . $self->value() . " +/- " . $self->std_error();
}

sub pcr_name {
    my $self = shift;
    my $pcr_name = ($self->gel_lanes)[0]->pcr_product_id->to_string;
    $pcr_name =~ s/repl (\d+)//g;
    return $pcr_name;
}

# XXX TODO: Finally remove usage of parseKey and the string "key" in general.
# -trs, 11 Jan 2016
sub name {
    my $self = shift;
    my $name = __PACKAGE__->parseKey($self->key());
    return $name;
}

sub parseKey {
    my ($pckg, $key) = @_;

    my($template_mat, $all_primers, $enzymes) = split(/\//, $key);
    my ($type, $id) = $template_mat =~ /([a-z]+)_(\d+)/;
    my %type_model = (
        bisulfite  => "bisulfite_converted_dna",
        rt         => "rt",
        sample     => "sample",
        extraction => "extraction",
    );
    my @round_primers = split(/-/, $all_primers);
    my @enzymes = split(/_/, $enzymes);
    my $type_package = "Viroverse::Model::" . $type_model{$type};
    my $template = $type_package->retrieve($id);
    my $name = $template->to_string();
    my $num_rnd = scalar(@round_primers);
    for (my $i = 0 ; $i < $num_rnd ; $i++ ){
    $name .= " rnd " . ($num_rnd - $i) . " (";
    my @primers = map {Viroverse::Model::primer->retrieve($_)} split(/_/, $round_primers[$i]);
    $name .= join ", ", map {$_->name} sort { ($a->orientation || $a->name) cmp ($b->orientation || $b->name) } @primers;
    $name .= ") ";
        $name .= $enzymes[$i]
            ? Viroverse::Model::enzyme->retrieve($enzymes[$i])->nickname() . ";"
            : ";"; #evidently some pcr products don't have enzymes
    }

    return $name;
}

sub writeKey {
    my ($pckg, $template, $primers, $enzymes) = @_;

    return $template . "/" . join("-", @{$primers}) . "/" . join("_" , @{$enzymes});
}

=item fetchFromPCR
    returns an array for instantiated copy_number objects for the supplied pcr_product
    based on the copy number "key" (1st round template/primers/enzymes)
    array is sorted with most recent results first
=cut
sub fetchFromPCR(){
    my ($package, $pcr_product) = @_;

    my $cur_pcr = $pcr_product;
    my $t = $pcr_product->pcr_template_id;
    my @primers;
    my @enzymes;
    while($cur_pcr){
    my @cur_primers = $cur_pcr->primers();
    push(@primers, join("_", sort{$a <=> $b } map ($_->primer_id, @cur_primers)));
     if(defined($cur_pcr->enzyme_id())){
        push(@enzymes, $cur_pcr->enzyme_id->enzyme_id());
     }else{
         push(@enzymes, undef);
     }

    $t = $cur_pcr->pcr_template_id;
    $cur_pcr = $t->pcr_product_id();
    }

    my $first_temp = $t->rt_product_id ?         "rt_" . $t->rt_product_id :
                     $t->extraction_id ? "extraction_" . $t->extraction_id :
                     $t->sample_id     ?     "sample_" . $t->sample_id     :
                     $t->bisulfite_converted_dna_id
                                       ?  "bisulfite_" . $t->bisulfite_converted_dna_id :
                                           "" ;    # For lack of a better fallback value…

    my $key = $first_temp . "/" . join("-", @primers) . "/" . join("_", @enzymes);

    my $session = Viroverse::session->new(__PACKAGE__->db_Main);
    my @ret;
    my $sql = qq[
            SELECT *
            FROM  viroserve.copy_number
            WHERE key = ?

            ORDER BY date_created DESC
        ];
    my $st =$session->{'dbr'}->prepare($sql);
    $st->execute(($key));
    my $results_r = $st->fetchall_arrayref({});

    foreach (@{$results_r}){
    push(@ret, bless Viroverse::db::mk_obj($session,$_));
    }

    return @ret;
}

1;
