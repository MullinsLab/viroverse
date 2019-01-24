use strict;
use warnings;

use Test::More;
use Test::Deep;

use_ok('Viroverse::Model::hla_genotype');

sub hla { Viroverse::Model::hla_genotype->parse_genotype(shift) }

sub expected {
    my %hash = @_;

    # convenience
    $hash{$_->[1]} = delete $hash{$_->[0]} for
        [ syn_poly   => 'synonymous_polymorphism' ],
        [ utr_poly   => 'utr_polymorphism'        ],
        [ expression => 'expression_level'        ],
        [ ambiguity  => 'ambiguity_group'         ];

    return {
        locus                   => undef,
        workshop                => undef,
        type                    => undef,
        subtype                 => undef,
        synonymous_polymorphism => undef,
        utr_polymorphism        => undef,
        expression_level        => undef,
        ambiguity_group         => undef,
        %hash
    }
}

sub cmp_hla($$;) {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $string = shift;
    my $hash   = shift || {};
    cmp_deeply(hla($string), expected(%$hash), shift || $string);
}

cmp_hla "A*02:01",          { locus => "A", type => "02", subtype => "01" };
cmp_hla "A*0201",           { locus => "A", type => "02", subtype => "01" };
cmp_hla "Aw*0201",          { locus => "A", type => "02", subtype => "01", workshop => "W" };
cmp_hla "A*02:01:03",       { locus => "A", type => "02", subtype => "01", syn_poly => "03" };
cmp_hla "A*020103",         { locus => "A", type => "02", subtype => "01", syn_poly => "03" };
cmp_hla "A*02:01:03:04",    { locus => "A", type => "02", subtype => "01", syn_poly => "03", utr_poly => "04" };
cmp_hla "A*02010304",       { locus => "A", type => "02", subtype => "01", syn_poly => "03", utr_poly => "04" };

cmp_hla "A*02:101:03:04",   { locus => "A", type => "02", subtype => "101", syn_poly => "03", utr_poly => "04" };

cmp_hla "A*02:01:03:04L",    { locus => "A", type => "02", subtype => "01", syn_poly => "03", utr_poly => "04", expression => "L" };
cmp_hla "A*02010304N",       { locus => "A", type => "02", subtype => "01", syn_poly => "03", utr_poly => "04", expression => "N" };

cmp_hla "DQA1*05:01:01G",    { locus => "DQA1", type => "05", subtype => "01", syn_poly => "01", ambiguity => "G" };

cmp_hla "DPB1*141",          { locus => "DPB1", type => "141" };

# XXX TODO: Test that other strings fail parsing as expected
# XXX TODO: Generate valid and invalid HLAs through combinatorics and try to parse them

done_testing;
