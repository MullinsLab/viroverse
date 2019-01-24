use utf8;
package ViroDB::Result::CohortPatientSummary;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

ViroDB::Result::CohortPatientSummary

=cut

use strict;
use warnings;

=head1 BASE CLASS: L<ViroDB::Result>

=cut

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'ViroDB::Result';

=head1 COMPONENTS LOADED

=over 4

=item * L<ViroDB::InflateColumn::JSON>

=back

=cut

__PACKAGE__->load_components("+ViroDB::InflateColumn::JSON");
__PACKAGE__->table_class("DBIx::Class::ResultSource::View");

=head1 TABLE: C<viroserve.cohort_patient_summary>

=cut

__PACKAGE__->table("viroserve.cohort_patient_summary");

=head1 ACCESSORS

=head2 cohort_id

  data_type: 'smallint'
  is_nullable: 1

=head2 patient_id

  data_type: 'integer'
  is_nullable: 1

=head2 name

  data_type: 'text'
  is_nullable: 1

=head2 estimated_date_infected

  data_type: 'date'
  is_nullable: 1

=head2 art_initiation_date

  data_type: 'date'
  is_nullable: 1

=head2 first_visit

  data_type: 'date'
  is_nullable: 1

=head2 latest_visit

  data_type: 'date'
  is_nullable: 1

=head2 viral_load_values

  data_type: 'json'
  is_nullable: 1

=head2 fiebig_stages

  data_type: 'json'
  is_nullable: 1

=head2 pbmc_count

  data_type: 'bigint'
  is_nullable: 1

=head2 plasma_count

  data_type: 'bigint'
  is_nullable: 1

=head2 leuka_count

  data_type: 'bigint'
  is_nullable: 1

=head2 other_count

  data_type: 'bigint'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "cohort_id",
  { data_type => "smallint", is_nullable => 1 },
  "patient_id",
  { data_type => "integer", is_nullable => 1 },
  "name",
  { data_type => "text", is_nullable => 1 },
  "estimated_date_infected",
  { data_type => "date", is_nullable => 1 },
  "art_initiation_date",
  { data_type => "date", is_nullable => 1 },
  "first_visit",
  { data_type => "date", is_nullable => 1 },
  "latest_visit",
  { data_type => "date", is_nullable => 1 },
  "viral_load_values",
  { data_type => "json", is_nullable => 1 },
  "fiebig_stages",
  { data_type => "json", is_nullable => 1 },
  "pbmc_count",
  { data_type => "bigint", is_nullable => 1 },
  "plasma_count",
  { data_type => "bigint", is_nullable => 1 },
  "leuka_count",
  { data_type => "bigint", is_nullable => 1 },
  "other_count",
  { data_type => "bigint", is_nullable => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2017-10-23 12:21:22
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:CsFW+hER6U8Pz8OxNAS1/g

__PACKAGE__->belongs_to(
  "patient",
  "ViroDB::Result::Patient",
  { patient_id => "patient_id" },
  {
    cascade_copy     => 0,
    cascade_delete   => 0,
  },
);

use List::Util qw< minstr max min >;
use Viroverse::Logger qw < :log >;
use Try::Tiny;
use DateTime::Format::Duration;

sub viral_loads_scaled {
    my $self = shift;
    my $vls = $self->viral_load_values;
    return unless $vls && @$vls > 1;

    my $format = sub {
        my ($ymd) = @_;
        my @ymd = split /-/, $ymd;
        return DateTime->new(
            year  => $ymd[0],
            month => $ymd[1],
            day   => $ymd[2],
        );
    };

    my $min_date = $format->( minstr map { $_->[0] } @$vls );
    my @xy_pts = sort { $a->[0] <=> $b->[0] } map {
        my @xy = @$_;
        my $x_date = $format->($xy[0]);
        my $diff = $x_date->delta_days($min_date)->in_units( 'days' );
        my $log_y = $xy[1] ? log $xy[1] : 0;
        [ $diff, $log_y ];
    } @$vls;

    return \@xy_pts;
}

sub highest_viral_load {
    my $self = shift;
    my $vls = $self->viral_load_values;
    return unless $vls && @$vls >= 1;
    return max map { $_->[1] } @$vls;
}

sub lowest_viral_load {
    my $self = shift;
    my $vls = $self->viral_load_values;
    return unless $vls && @$vls >= 1;
    return min map { $_->[1] } @$vls;
}

my $interval_in_days = DateTime::Format::Duration->new(pattern => '%j');

sub years_infected {
    my $self = shift;
    if ($self->latest_visit && $self->estimated_date_infected)  {
        my $duration = $self->latest_visit->subtract_datetime($self->estimated_date_infected);
        return $interval_in_days->format_duration($duration)/365.25;
    }
}

sub days_to_first_art {
    my $self = shift;
    if ($self->estimated_date_infected && $self->art_initiation_date) {
        my $duration = $self->art_initiation_date->subtract_datetime($self->estimated_date_infected);
        return $interval_in_days->format_duration($duration);
    }
    return undef;
}

__PACKAGE__->meta->make_immutable;
1;
