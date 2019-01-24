package Viroverse::Model::hla_genotype;

use strict;
use warnings;
use base 'Viroverse::CDBI';
use Carp qw[carp];
use Time::HiRes qw[time];
use Data::Dumper qw< Dumper >;

__PACKAGE__->table('viroserve.hla_genotype');
__PACKAGE__->columns(All => qw[
    hla_genotype_id
    mhc_class
    locus
    workshop
    type
    subtype
    synonymous_polymorphism
    utr_polymorphism
    expression_level
    supertype
]);

# UTR = untranslated region (non-coding)

#should be able to do this with the CDBI methods, but Viroverse::patient doesn't play that game yet.
__PACKAGE__->set_sql(by_patient_locus => q[
    SELECT __ESSENTIAL__
      FROM __TABLE__
      JOIN viroserve.patient_hla_genotype USING (hla_genotype_id)
     WHERE patient_id = ?
        AND locus = ?
]);

sub parse_genotype {
    my ($self, $string) = @_;
    return unless $string;

    $string =~ s/^\s+|\s+$//g;

    # Refer to http://hla.alleles.org/nomenclature/naming.html
    # 
    # Note that DRB1*121 is the new nomenclature for a set of alleles, but
    # doesn't have a distinguishing colon to give it away.  The old
    # nomenclature _should_ never have a 3-digit type + subtype
    # specification (of course, people do abbreviate, e.g. A*0401 as A*401).

    my %parsed;
    if ($string =~ /:/ or $string =~ /\*\d{3}$/) {
        # new nomenclature
        $string =~ m/^
            (?:HLA-)?
            (?<locus>[A-Z][A-Z0-9]*)(?<workshop>w)?
            \*?
            (?<type>\d+)
            (?: : (?<subtype>\d+)
                (?: : (?<syn_poly>\d+)
                    (?: : (?<utr_poly>\d+))? )? )?
            (?<expression>[NLSCAQ])?
            (?<ambiguity>[PG])?
        $/x;
        %parsed = %+;
    } else {
        $string =~ m/^
            (?:HLA-)?
            (?<locus>[A-Z][A-Z0-9]*)(?<workshop>w)?
            \*?
            (?<type>\d\d)
            (?: (?<subtype>\d\d)
                (?: (?<syn_poly>\d\d)
                        (?<utr_poly>\d\d)? )? )?
            (?<expression>[NLSCAQ])?
            (?<ambiguity>[PG])?
        $/x;
        %parsed = %+;
    }

    if (not $parsed{locus}) {
        carp "bad parse of <$string>";
        return;
    }

    # Make sure all keys exist so we're explicit about missing values; this is
    # useful for search.
    $parsed{$_} //= undef
        for qw( locus workshop type subtype syn_poly utr_poly expression ambiguity );

    $parsed{workshop} = $parsed{workshop} ? 'W' : undef;
    $parsed{$_->[1]}  = delete $parsed{$_->[0]} for
        [ syn_poly      => 'synonymous_polymorphism' ],
        [ utr_poly      => 'utr_polymorphism' ],
        [ expression    => 'expression_level' ],
        [ ambiguity     => 'ambiguity_group' ];

    return \%parsed;
}

sub retrieve_by_genotype {
    my ($pkg,$string) = @_;
    if (!length($string)) {
        carp "no string passed";
        return;
    }

    my $parsed = $pkg->parse_genotype($string)
        or return;

    my @res = $pkg->search_where($parsed, { order_by => 'hla_genotype_id' });

    if (@res == 0) {
        if ($parsed->{workshop}) { # try again without workshop?
            local $parsed->{workshop} = undef;
            my @no_w = $pkg->search_where($parsed, { order_by => 'hla_genotype_id' });

            if (@no_w == 0) {
                carp "couldn't find HLA <$string> with: ", Dumper($parsed);
                return;
            } elsif (@no_w > 1) {
                carp "found ".scalar @res." HLAs for <$string> (ignoring workshop), returning first";
            }

            carp "ignoring workshop for HLA <$string>";
            return $no_w[0];
        }
    } elsif (@res > 1) {
        carp "found ".scalar @res." HLAs for <$string>, returning first";
    }
    return $res[0];
}

1;
