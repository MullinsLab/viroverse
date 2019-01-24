use strict;
use warnings;
use utf8;
use 5.018;

package Viroverse::Breadcrumbs;
use Moo;
use Types::Standard -types;
use Types::Common::String qw< NonEmptyStr >;
use Viroverse::Types qw< ViroDBRecord >;
use namespace::clean;

has 'page_record' => (
    is       => 'ro',
    isa      => ViroDBRecord["Patient"]
              | ViroDBRecord["Sample"]
              | ViroDBRecord["NucleicAcidSequence"],
    required => 1,
);

has 'context' => (
    is       => 'ro',
    isa      => InstanceOf["Viroverse"],
    required => 1,
);

has 'leaf_label' => (
    is       => 'ro',
    isa      => Str,
    required => 0,
);

has 'breadcrumbs' => (
    is => 'lazy',
    isa => ArrayRef[Tuple[NonEmptyStr] | Tuple[NonEmptyStr, InstanceOf["URI"] ] ],
);

sub _build_breadcrumbs {
    my $self = shift;
    my @out;

    my $patient = $self->page_record->isa("ViroDB::Result::Patient") ?
                      $self->page_record :
                  $self->page_record->isa("ViroDB::Result::Sample") ?
                      $self->page_record->patient :
                  $self->page_record->sample ?
                      $self->page_record->sample->patient :
                      undef;

    push @out, $self->_patient_crumbs($patient) if $patient;

    if ($self->page_record->isa("ViroDB::Result::Sample")) {
        if ($patient) {
            push @out, [
                'Samples',
                $self->context->uri_for_action("/patient/show_tab_by_id", [ $patient->id ], 'samples'),
            ];
        } else {
            push @out, ['Samples', $self->context->uri_for_action("/sample/index") ];
        }
        push @out, [
            "Sample " . $self->page_record->id,
            $self->context->uri_for_action("/sample/show", [ $self->page_record->id ]),
        ];
    } elsif ($self->page_record->isa("ViroDB::Result::NucleicAcidSequence")) {
        if ($patient) {
            push @out, [
                'Sequences',
                $self->context->uri_for_action("/patient/show_tab_by_id", [ $patient->id ], 'sequences'),
            ];
        } else {
            push @out, ['Sequences', $self->context->uri_for_action("/sequence/index") ];
        }
        push @out, [
            "Sequence " . $self->page_record->idrev,
            $self->context->uri_for_action("/sequence/show", [ $self->page_record->idrev ]),
        ];
    }

    push @out, [$self->leaf_label] if ($self->leaf_label);

    return \@out;
}

sub _patient_crumbs {
    my ($self, $patient) = @_;
    my @out;
    push @out,
        [ "Subjects", $self->context->uri_for_action("/cohort/index") ],
        [
            $patient->primary_alias->cohort->name,
            $self->context->uri_for_action("/cohort/show", [ $patient->primary_alias->cohort->id ]),
        ]
        if $patient->primary_alias; # some old "patients" exist but have no alias/cohort
    push @out, [
        $patient->name,
        $self->context->uri_for_action("/patient/show_by_id", [ $patient->id ]),
    ];
    return @out;
}

1;
