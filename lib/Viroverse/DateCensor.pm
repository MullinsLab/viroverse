use strict;
use warnings;
use utf8;
use 5.018;

package Viroverse::DateCensor;
use Moo;
use Types::Standard qw< :types >;
use Types::Common::String qw< NonEmptySimpleStr >;
use Viroverse::Types qw< ViroDBRecord >;
use Viroverse::Logger qw< :log >;
use namespace::clean;

has strftime_format => (
    is       => 'ro',
    isa      => NonEmptySimpleStr,
    required => 1,
    default  => "%Y-%m-%d",
);

has relative_unit => (
    is       => 'ro',
    isa      => Enum[qw[ days weeks months years ]],
    required => 1,
    default  => 'days',
);

has censor => (
    is       => 'ro',
    isa      => Bool,
    required => 1,
);

has patient => (
    is       => 'ro',
    isa      => (ViroDBRecord['Patient'] | ViroDBRecord['CohortPatientSummary']),
    required => 0,
);

has reference_date => (
    is => 'ro',
    isa => InstanceOf['DateTime'],
    required => 0,
);

sub BUILD {
    my ($self, $args) = @_;
    die "One of patient xor reference_date is required"
        unless $args->{patient} xor $args->{reference_date};
}

sub represent_date {
    my ($self, $date) = @_;

    return undef unless
        (InstanceOf['DateTime'])->check($date);

    return $date->strftime($self->strftime_format)
        unless $self->censor;

    my ($day_0, $type);
    if ($self->reference_date) {
        $day_0 = $self->reference_date;
        $type = "";
    } elsif ($self->patient->estimated_date_infected) {
        $day_0 = $self->patient->estimated_date_infected;
        $type = "pi";
    } elsif ($self->patient->first_visit) {
        $day_0 = $self->patient->first_visit;
        $type = ""
    } else {
        # No basis for constructing any kind of relative date
        return "n/a";
    }

    my $duration = $date->subtract_datetime($day_0);

    my $format =
        $self->relative_unit eq "days"
            ? sub { DateTime::Format::Duration->new(pattern => "%j")
                ->format_duration($_[0])."d$type" } :
        $self->relative_unit eq "weeks"
            ? sub {
                DateTime::Format::Duration->new(pattern => "%V")
                ->format_duration($_[0])."w$type" } :
        $self->relative_unit eq "months"
            ? sub {
                my $months = DateTime::Format::Duration->new(pattern => "%j")
                    ->format_duration($_[0])/30;
                return sprintf "%.1fm%s", $months, $type;
            } :
        $self->relative_unit eq "years"
            ? sub {
                my $years = DateTime::Format::Duration->new(pattern => "%j")
                    ->format_duration($_[0])/365.25;
                return sprintf "%.1fy%s", $years, $type;
            } : die "unreachable";
    return $format->($duration);
}

1;
