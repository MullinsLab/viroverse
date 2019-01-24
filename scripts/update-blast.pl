#!/usr/bin/env perl
# update-blast.pl generates a fresh blast db every night
use strict;
use 5.018;
use Viroverse::CDBI;
use Viroverse::Model::sequence::dna;
use Viroverse::config;
use File::Temp qw< tempdir >;
use File::Copy qw< move copy >;
use File::Path qw< mkpath >;

my $destination = $Viroverse::config::blast_output_path;
my $makeblastdb = "$Viroverse::config::blast_bin_path/makeblastdb";
my $working_dir = tempdir('viroblast-update-XXXX', CLEANUP => 1, TMPDIR => 1) or die "unable to create tempdir: $!\n";
mkpath($destination);

my $seqs = Viroverse::CDBI->db_Main->selectall_arrayref('SELECT * FROM viroserve.na_sequence_latest_revision');

open FA,">$working_dir/viroverse";
foreach my $seq_r (@{$seqs}) {
    my $seq = Viroverse::Model::sequence::dna->retrieve(@$seq_r);
    unless ($seq) {
        warn "Can't load sequence #$seq_r->[0] (rev $seq_r->[1])";
        next;
    }
    print FA $seq->get_FASTA(
        sep    => '|',
        name   => [\'lcl|vv', qw[ name patient idrev scientist ]],
        filter => sub { s/[,;\s]/_/gr },
    );
}

my @makedb = ($makeblastdb, "-in", "$working_dir/viroverse", qw(-dbtype nucl -logfile /dev/null));
system(@makedb) == 0
    or die "Error running ", join(" ", @makedb), ": $!";

foreach my $ext ('', '.nhr', '.nin', '.nsq') {
    if (-e "$destination/viroverse$ext") {
        move("$destination/viroverse$ext","$destination/viroverse-old$ext")
            or die "Error moving $destination/viroverse$ext $!";
    }
    copy("$working_dir/viroverse$ext", $destination)
        or die "Error copying $working_dir/viroverse$ext $!";
}
