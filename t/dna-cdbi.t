use strict;
use Test::More;
use Test::LongString;

my $hxb2_id = 0;
my $hxb2_rev = 1;

use_ok('Viroverse::Model::sequence::dna');

#get
ok( my $hxb2 = Viroverse::Model::sequence::dna->retrieve($hxb2_id) );
ok( $hxb2 = Viroverse::Model::sequence::dna->retrieve($hxb2_id,$hxb2_rev) );

ok(Viroverse::Model::sequence::dna->retrieve_many(10,100,1000), "get_many");

SKIP: {
    skip 'search is not called, and not terribly well implemented', 1;
    ok(Viroverse::Model::sequence::dna->search( {name => 'HXB2CG'}),'search name = HXB2CG');
}

#standard properties
ok ( $hxb2->name );
ok ( $hxb2->entered_date );
ok ( $hxb2->scientist_id );

#deferred properties
ok ( $hxb2->seq );
TODO : {
    local $TODO = "need test sequence with sample" if 1;
    cmp_ok ( ref($hxb2->sample_id),
        'eq', 'Viroverse::sample', 'Deferred sample object'
     );
}

## methods inherited from sequence
cmp_ok ( length($hxb2->get_FASTA),
    '>', 8000, 'get_FASTA returnes reasonable length whole genome'
);

is_string $hxb2->fasta_description(name => [], sep => ':'),
          '0.1:HXB2CG:Brandon Maust', 'default fasta description, with custom sep';
is_string $hxb2->fasta_description(name => [\'vv', qw[ idrev name ]], sep => '|'),
          'vv|0.1|HXB2CG', 'customized fasta description';
is_string $hxb2->fasta_description(name => [qw[ idrev scientist ]], sep => 'x', filter => sub { uc s/\s+/_/gr }),
          '0.1xBRANDON_MAUST', 'filter fasta description';

done_testing;
