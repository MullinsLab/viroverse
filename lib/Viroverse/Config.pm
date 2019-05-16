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

# Sensible defaults without any configuration
sub defaults {
    my $unix_user = $ENV{USER} || `whoami`;
    my $hostname = `hostname -s` || 'unknown-host';
    chomp for $unix_user, $hostname;

    my $max_results_json = 1200;

    return {
        # node information
        instance_name       => "$unix_user-$hostname",
        debug               => $ENV{VVDEBUG} // 1,

        # contact
        help_name           => 'Your Local Viroverse Administrator',
        help_email          => $unix_user . '@' . $hostname,
        error_email         => $unix_user . '@' . $hostname,

        # storage
        storage             => "$ENV{VIROVERSE_ROOT}/var/storage",

        # database
        dsn                 => 'dbi:Pg:host=127.0.0.1;dbname=viroverse;port=5432',
        read_only_user      => 'viroverse_r',
        read_only_pw        => '',
        read_write_user     => 'viroverse_w',
        read_write_pw       => '',

        # Viroverse's local ViroBLAST install paths
        #
        # These defaults likely won't work unless var/viroblast is a checkout of
        # viroverse-viroblast.git (or a symlink to one).
        blast_bin_path      => "$ENV{VIROVERSE_ROOT}/var/viroblast/blast+/bin/",
        blast_output_path   => "$ENV{VIROVERSE_ROOT}/var/viroblast/db/nucleotide/",

        # Product finder limit
        max_results_json    => $max_results_json,

        # TT2 template defaults
        template_defaults => {
            date_format         => '%Y-%m-%d',
            max_results_json    => $max_results_json,
        },

        # External executables
        needle              => '/usr/local/bin/needle',
        quality             => '/usr/local/bin/quality',

        # Enabled features
        features => {
            ice_cultures    => 0,
            epitopedb       => 0,
            isla_sequences  => 0,
            censor_dates    => 0,
        },
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
