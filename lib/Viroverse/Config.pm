use strict;
use warnings;
use 5.010;

package Viroverse::Config;
use Moo;
use Types::Standard qw< :types >;
use Types::Common::String qw< NonEmptyStr >;
use Config::Any;
use Hash::Merge qw< merge >;
use List::Util qw< reduce pairvalues pairmap >;
use Path::Tiny;

has stems => (
    is       => 'ro',
    isa      => ArrayRef[NonEmptyStr],
    required => 1,
    default  => sub {[
        # Stem order is important for precedence
        map { path(__FILE__)->parent(3)->child($_)->stringify }
            qw[ viroverse_local viroverse ]
    ]},
);

has values => (
    is       => 'lazy',
    isa      => HashRef,
    init_arg => undef,
);

$ENV{VIROVERSE_ROOT} //= path(__FILE__)->parent(3)->realpath->stringify;

=pod

=item defaults()

This provides the default hash for things which are dependent on the runtime
environment. All other defaults are set in viroverse.conf in the project root.

=cut
sub defaults {
    my $unix_user = $ENV{USER} || `whoami`;
    my $hostname = `hostname -s` || 'unknown-host';
    chomp for $unix_user, $hostname;

    return {
        # Default instance name
        instance_name       => "$unix_user-$hostname",

        # Default debug flag
        debug               => $ENV{VVDEBUG} // 1,

        # Default contact address
        help_email          => $unix_user . '@' . $hostname,

        # Default error email destination
        error_email         => $unix_user . '@' . $hostname,

        # Default storage directory
        storage             => "$ENV{VIROVERSE_ROOT}/var/storage",

        # Default locations of ViroBlast facets
        blast_bin_path      => "$ENV{VIROVERSE_ROOT}/var/viroblast/blast+/bin/",
        blast_output_path   => "$ENV{VIROVERSE_ROOT}/var/viroblast/db/nucleotide/",
    };
};


sub _build_values {
    my $self = shift;
    my $conf = Config::Any->load_stems({
        stems   => $self->stems,
        use_ext => 1,

        # Allow the use of [] to make Config::General settings explicitly an
        # array even if only used once.
        driver_args => {
            General => { -ForceArray => 1 },
        },
    });

    push @$conf, { defaults => defaults };

    return reduce { merge($a, $b) } +{},
              map { pairvalues %$_ }
                  @$conf;
}

sub conf {
    my $self = shift;
    state $singleton = $self->new;

    return $singleton->values;
}

1;
