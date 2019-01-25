use strict;
use warnings;
use 5.010;

package Viroverse::config;
use Path::Tiny;

$ENV{VIROVERSE_ROOT} //= path(__FILE__)->parent(3)->realpath->stringify;

my $unix_user = $ENV{USER} || `whoami`;
my $hostname  = `hostname -s` || 'unknown-host';
chomp for $unix_user, $hostname;

our $instance_name = "$unix_user-$hostname";
our $debug         = $ENV{VVDEBUG} // 1;

our $storage = "$ENV{VIROVERSE_ROOT}/var/storage";

# Database
our $dsn        = 'dbi:Pg:host=127.0.0.1;dbname=viroverse;port=5432';
our $read_only_user  = 'viroverse_r';
our $read_only_pw    = '';
our $read_write_user    = 'viroverse_w';
our $read_write_pw      = '';

# Contact
our $help_name   = 'Your Local Viroverse Administrator';
our $help_email  = $unix_user . '@' . $hostname;
our $error_email = $unix_user . '@' . $hostname;

# Viroverse's local ViroBLAST install paths
#
# These defaults likely won't work unless var/viroblast is a checkout of
# viroverse-viroblast.git (or a symlink to one).
our $blast_bin_path    = "$ENV{VIROVERSE_ROOT}/var/viroblast/blast+/bin/";
our $blast_output_path = "$ENV{VIROVERSE_ROOT}/var/viroblast/db/nucleotide/";

# External executables
our $needle            = '/usr/local/bin/needle';
our $quality           = '/usr/local/bin/quality';

# Limits number of records served via JSON for product finder
our $max_results_json = 1200;

# Default parameters passed to all TT2 templates
our $template_defaults = {
    date_format         => '%Y-%m-%d',
    max_results_json    => $max_results_json,
};

# Feature flags; to enable these, set their individual values to 1 in the
# lib/Viroverse/config_local.pm file
our $features = {
    ice_cultures => 0,
    epitopedb => 0,
    isla_sequences => 0,
};

# Load up our local overrides, if any.
eval {
    require Viroverse::config_local
};
die "Couldn't load Viroverse::config_local: $@"
    if $@ and $@ !~ /^Can't locate Viroverse\/config_local.pm /;

1;
