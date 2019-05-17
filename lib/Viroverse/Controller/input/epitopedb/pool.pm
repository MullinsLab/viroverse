
package Viroverse::Controller::input::epitopedb::pool;
use base 'Viroverse::Controller';

use strict;
use warnings;

use Viroverse::epitopedb::input;
use Viroverse::epitopedb::search;
use EpitopeDB;
use Text::ParseWords;
use Data::Dumper;
use Carp;

=head1 NAME

Viroverse::Controller::input::epitopedb - Holds Catalyst actions under /input/epitopedb to add with ELISpot data to VV

=head1 SYNOPSIS

See L<Viroverse>

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=item begin
=cut

my $schema = EpitopeDB->connect(Viroverse::Config->conf->{dsn}, Viroverse::Config->conf->{read_write_user},Viroverse::Config->conf->{read_write_pw});

sub section {
    return 'input';
}

sub subsection {
    return 'epitope';
}


sub index : Private {
    my ($self, $context) = @_;
    $context->stash->{template} = 'epitopedb/pool.tt';
}

sub result : Local {
    my ($self, $c) = @_;
    my $upload = $c->request->upload('inputfile');

    if ($upload) {
        my $records;
        my $i = 0;
        my $validate_flag = 1;
        my $exist = my $new = my $total = 0;

        my $fh = $upload->fh;
        my @buffer = <$fh>;
        my $lines_ref = Viroverse::epitopedb::input::getFileLines (\@buffer);
        foreach my $line (@$lines_ref) {
            unless ($line =~ /^Pool name/i || $line =~ /^\s*$/) {
                my @fields = quotewords ('\t', 0, $line);
                my @cleanFields = Viroverse::epitopedb::input::cleanFields (\@fields);
                my $pool_name = uc $cleanFields[0];
                my $pept_seq = uc $cleanFields[1];
                my $pept_name = uc $cleanFields[2];

                if ($pept_name || $pept_seq) {
                    if (!$pool_name) {
                        $c->stash->{status} = "missing fields";
                        $validate_flag = 0;
                        last;
                    }
                }else {
                    $c->stash->{status} = "missing fields";
                    $validate_flag = 0;
                    last;
                }

                if ($pept_seq && $pept_seq !~ /^[A-Z]+$/) {
                    $c->stash->{status} = "Peptide sequence $pept_seq is not in correct format";
                    $validate_flag = 0;
                    last;
                }

                my $pept_id = Viroverse::epitopedb::input::get_pept_id($schema, $pept_name, $pept_seq);
                if (!$pept_id) {
                    $c->stash->{status} = "Couldn't find peptide $pept_name $pept_seq";
                    $validate_flag = 0;
                    last;
                }

                $records->{$i} = ();
                push @{$records->{$i}}, $pool_name, $pept_id;
                $i++;
            }
        }
        if ($validate_flag) {
            foreach my $row (sort {$a <=> $b} keys %$records) {
                my @fields = @{$records->{$row}};
                my $pool_name = $fields[0];
                my $pept_id = $fields[1];

                my ($pool_id, $status) = Viroverse::epitopedb::input::get_pool_pool_id($schema, $pool_name, $pept_id);
                if ($status eq "exist") {
                    $exist++;
                }elsif ($status eq "new") {
                    $new++;
                }
                $total++;
            }
            $c->stash->{status} = "Manipulated total $total records:<br>
                                    $exist of them exist in database<br>
                                    $new of them input into database<br>";
        }
        $c->stash->{template} = 'epitopedb/pool.tt';
    }else {
        my $pool_name = uc $c->req->param("pool_name");
        my $pept_name = uc $c->req->param("pept_name");
        my $pept_seq = uc $c->req->param("pept_seq");

        my $pept_id = Viroverse::epitopedb::input::get_pept_id($schema, $pept_name, $pept_seq);
        if (!$pept_id) {
            $c->response->body('Error: unable to resolve peptide, please import the peptide first');
            return;
        }

        my ($pool_id, $status) = Viroverse::epitopedb::input::get_pool_pool_id($schema, $pool_name, $pept_id);

        $c->stash->{type} = "pool";
        $c->stash->{status} = $status;
        $c->stash->{template} = 'epitopedb/epitopedb_input_sidebar.tt';
    }
}



1;
