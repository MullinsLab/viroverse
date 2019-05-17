package Viroverse::sample;
use Moo;
BEGIN { extends 'Viroverse::CDBI' } # trying out db_Main, -bmaust, 20 Oct 2009
use Types::Standard qw< :types >;
use namespace::clean;

use Viroverse::session;
use Viroverse::db;
use Data::Dumper;
use Carp qw[croak carp confess cluck];
use SQL::Abstract;
use strict;

with 'Viroverse::Model::enumerable';

## Viroverse sample handling, bmaust July, 2005
#  most of these functions will probably be handled by patient and sequence objects, not used directly

#valid properties for the object.  value 1 means they can be user-manipulated, 0 means assigned by app/db
my %properties = ('received_date'=>1,'name'=>'1',note=>1,'sampleid'=>0,'session'=>0,'patient_name'=>0, 'tissue_type_id' => 1, 'additive_id' => 1);

#properties valid for the object not stored directly in its corresponding db table
my %properties_ext  = ('sample_type'=>1,'tissue_type'=>1,'additive_id'=>1);

#properties valid for the samples but stored in the visit table
my %properties_visit  = ('patientid'=>'1','date'=>'1','visit_number'=>'1','visitid'=>'0');

#keeps track of what properties are where for joins and inserts
my %prop_col = (
    'sampleid'        => 'viroserve.sample.sample_id',
    'name'            => 'viroserve.sample.name',
    'patientid'     => 'viroserve.visit.patient_id',
    'date'          => 'viroserve.visit.visit_date',
    'tissue_type'   => 'viroserve.tissue_type.name',
    'additive'      => 'viroserve.additive.name',
    'sample_type'   =>'viroserve.sample_type.name',
    'visitid'       => 'viroserve.visit.visit_id',
    'visit_number'  => 'viroserve.visit.visit_number',
);

# Used by the legacy search() function
my %case_insensitive_props = (
    name            => 1,
    tissue_type     => 1,
    sample_type     => 1,
    additive        => 1,
    visit_number    => 1,   # really a string, not a number
);

my %deferred_props = (
    notes => sub {
        my $self = shift;
        return $self->{notes} if $self->{notes};

        # Filled in during a search, but not a get()
        unless ($self->{sample_notes}) {
            $self->{sample_notes} = $self->{session}->{'dbr'}->selectcol_arrayref(
                q[ SELECT note FROM viroserve.notes WHERE vv_uid = ?  ],
            undef, $self->get_prop('vv_uid'));
        }

        $self->{notes} = [];
        push @{ $self->{notes} }, @{ $self->{sample_notes} };   # viroserve.notes.note

        return $self->{notes};
    },
);

# Moo init
has [qw(sampleid name patientid date tissue_type additive sample_type visitid visit_number received_date vv_uid patient_name viral_load assigned_scientist)] => ( isa => Value, is => 'ro');
has 'notes' => (
    isa => ArrayRef,
    is => 'ro',
    lazy => 1,
    default => $deferred_props{'notes'}
);

my %sample_sel = (
    fields => qq[
     sample.sample_id as sampleid,
     sample.vv_uid as vv_uid,
     sample.name as sample_name,
     sample_type.name as sample_type,
     tissue_type.name as tissue_type,
     additive.name as additive,
     received_date,
     visit_date as "date",
     visit_number,
     visit.vv_uid as visit_vv_uid,
     visit.visit_id as visitid,
     patient_id,
     viroserve.patient_name(patient_id) as patient_name,
     sample.date_added
    ],

    tables => qq[viroserve.sample
     LEFT JOIN viroserve.sample_type
         USING (sample_type_id)
     LEFT JOIN viroserve.tissue_type
         USING (tissue_type_id)
     LEFT JOIN viroserve.additive
         USING (additive_id)
     LEFT JOIN viroserve.visit
        ON (visit.visit_id = sample.visit_id AND NOT visit.is_deleted)],
);

# This query fragment gets ANDs concatenated to it in various places and I had
# to get rid of "NOT sample.is_deleted" and I didn't want to rewrite more than
# I absolutely had to so here you go, the worst thing you've seen today
my $sample_sel_sql = qq[
    SELECT
        $sample_sel{fields}
    FROM
        $sample_sel{tables}
    WHERE 1=1
];

my %detailed_sample_sel = (cols =>q[
    SELECT
     sample.sample_id as sampleid,
     sample.vv_uid as vv_uid,
     sample.name as sample_name,
     tissue_type.name as tissue_type,
     additive.name as additive,
     sample_type.name as sample_type,
     received_date,
     visit_date as date,
     visit_number,
     visit.vv_uid as visit_vv_uid,
     visit.visit_id as visitid,
     viroserve.patient_name(visit.patient_id) as patient_name,
     visit.patient_id,
     patient_names,
     array_accum(distinct sample_notes.note) as sample_notes,
     viral_load,
     project_scientist.name as assigned_scientist,
     sample.date_added
    FROM
     viroserve.sample
     LEFT JOIN viroserve.tissue_type
        USING (tissue_type_id)
     LEFT JOIN viroserve.additive
         USING (additive_id)
     LEFT JOIN viroserve.sample_type
        USING (sample_type_id)
     LEFT JOIN viroserve.visit
        ON (visit.visit_id = sample.visit_id AND NOT visit.is_deleted)
     LEFT JOIN viroserve.notes sample_notes
        ON (sample_notes.vv_uid = sample.vv_uid)
     LEFT JOIN (
        SELECT patient_id,visit_date as lab_date,viral_load
          FROM viroserve.viral_load
        ) labs
        ON ((lab_date = visit_date OR (lab_date IS NULL AND visit_date IS NULL)) AND labs.patient_id = visit.patient_id)
     LEFT JOIN
        ( SELECT patient_id,cohort_id,array_accum(distinct external_patient_id) as patient_names
            FROM viroserve.patient_alias
            group by patient_id,cohort_id
        ) names
        ON (visit.patient_id = names.patient_id)
        LEFT JOIN viroserve.project_materials
            ON (sample.sample_id=project_materials.sample_id)
        LEFT JOIN viroserve.scientist project_scientist
            ON (project_scientist.scientist_id = project_materials.desig_scientist_id)

],
    group_by => q[    GROUP BY sample.sample_id,sample.name,tissue_type,additive,sample_type,received_date,visit_date,visit_number,visit_vv_uid,visitid, visit.patient_id, patient_name,patient_names,viral_load,sample.vv_uid, project_scientist.name, sample.date_added ]
);

our @expand_these = qw[patient_names];

# returns a sample with supplied database identifier
#TODO: multiple gets at one time
sub get {
    my ($session, $sample_id) = (shift, shift);
    unless (defined $session && $sample_id >= 1) {
        confess("get() needs a session and sample_id\n");
    }

    unless (ref $session) {
        croak "need a Viroverse::session, not a ".(ref $session);
    }
    my $sql = $sample_sel_sql.' AND sample_id = ?';
    my $sh = $session->{'dbr'}->prepare($sql);
    my $sample_row = $session->{'dbr'}->selectrow_hashref($sh,undef,($sample_id));
    if (defined $sample_row) {
        return bless Viroverse::db::mk_obj($session,$sample_row);
    }
    else {
        carp("no sample found with $sample_id");
        return undef;
    }
}


=item get_patient_samples
returns a hashref of samples for a patient_id

bmaust modified 2007-02-02 to take a third parameter to filter out samples w/o tissue types
=cut
sub get_patient_samples {

    my ($session,$patient_id,$only_real,$blessme) = (shift, shift,shift,shift);

    die 'umm...need a patient to find samples' unless $patient_id;

    my $sql = $detailed_sample_sel{cols}."\n WHERE visit.patient_id = ?\n";

    if ($only_real) {
        #sad that this is a left join and where filter rather than skipping rows...
        $sql .= ' AND tissue_type_id is not null ';
    }

    $sql .= $detailed_sample_sel{group_by};

    my $result = $session->{'dbr'}->selectall_hashref($sql,'sampleid',undef,$patient_id);

    if (!$blessme) {
        return $result;
    } else {
        my @return;
        foreach my $row_ref ( values %{$result} ) {
            push @return, bless Viroverse::db::mk_obj($session,$row_ref);
        }

        return @return;
    }

}

sub get_prop {
    my ($self,$prop) = (shift, shift);
    if (exists $deferred_props{$prop}) {
        $self->{$prop} = &{$deferred_props{$prop}}($self);
    }
    if (exists $self->{$prop}) {
        return $self->{$prop};
    }
    carp "$prop not set!";
    return undef;
}

sub to_string {
    my $self = shift;

    return join ' ',(
        $self->{sample_name} || '',
        $self->{patient_name} || 'unknown patient',
        $self->{date} || 'unknown date' ,
        $self->{tissue_type} || ''
    );

}

sub give_id {
    my $self = shift;

    return $self->{'sampleid'};
}

sub extractions {
    my $self = shift or croak "this is a instance method";

    use Viroverse::Model::extraction;
    my @extractions = Viroverse::Model::extraction->search(sample_id=>$self->give_id);

    return @extractions;
}

sub list_tissue_types {
    my ($pkg, $session) = @_;
    confess "$session is not a session" unless ref $session eq 'Viroverse::session';
    return Viroverse::db::selectall_hr($session,q[SELECT tissue_type.name,tissue_type_id from viroserve.tissue_type],'tissue_type_id');

}

sub table {
    return 'viroserve.sample';
}

sub columns {
    my ($pkg,$set) = @_;
    if (!$set || $set eq 'Primary') {
        return 'sample_id';
    } else {
        die 'unimplemented';
    }
}

sub construct {
    my ($pkg, $row_ref) = @_;

    my $s = Viroverse::session->new(__PACKAGE__->db_Main);
    return get($s,$row_ref->{'sample_id'});
}

sub retrieve {
    my ($pkg, $id) = @_;

    my $s = Viroverse::session->new(__PACKAGE__->db_Main);

    warn "retrieved sample $id";
    return get($s,$id);
}

#this gets called on CDBI objects and uses the wrong get(), so overriding
sub stringify_self {
    my $self = shift;
    return $self->get_prop('sampleid');
}

=head2 copy_numbers

Returns a list of L<Viroverse::Model::copy_number> objects relevant to this
sample (either by an RT product, extraction, bisulfite conversion, or direct
PCR).

=cut

sub copy_numbers {
    my $self = shift;
    return Viroverse::Model::copy_number->search_by_sample($self->give_id);
}

sub TO_JSON {
    my $self = shift;
    my $notes = $self->get_prop('notes');
    if (ref $notes && @{$notes} > 0) {
        $notes = join(',',grep {defined} @{$notes})
    }

    return {
        id => $self->give_id,
        collection_date => $self->get_prop('date'),
        subject => $self->get_prop('patient_name'),
        tissue => $self->get_prop('tissue_type'),
        notes => $notes,
        name => $self->to_string(),
        sample_name => $self->get_prop('sample_name'),
        scientist => $self->assigned_scientist,
        viral_load => $self->viral_load
    }
}
1;
