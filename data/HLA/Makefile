SHELL := /bin/bash
recs  := ./recs

all: new-ambiguity-groups-deploy.sql new-genotypes-deploy.sql everything-deploy.sql

data: hla_nom.txt hla_nom_g.txt hla_nom_p.txt

$(recs):
	curl -fsSL https://recs.pl > $@
	chmod +x $@

hla_nom.txt hla_nom_g.txt hla_nom_p.txt: %:
	wget -N http://hla.alleles.org/wmda/$@

new-ambiguity-groups-deploy.sql: generate-sql hla_nom_g.txt hla_nom_p.txt
	carton exec -- perl $^ --new --output new-ambiguity-groups

new-ambiguity-groups-revert.sql new-ambiguity-groups-verify.sql: new-ambiguity-groups-deploy.sql

hla_nom_filtered.txt: hla_nom.txt | $(recs)
	grep -vE '^#' $< \
		| $(recs) fromsplit -d ';' -k locus,allele,assigned,deleted,duplicate,reason \
		| $(recs) grep 'not {{deleted}} and {{allele}} =~ /:/' \
		| $(recs) eval 'join ";", {{locus}}, "", {{allele}}' \
		> $@
	# Also generate fake genotypes which are just type and type/subtype.  These
	# are useful when the resolution of an HLA test is coarse.
	$(recs) fromsplit -d ';' -k locus,empty,allele $@ \
		| $(recs) xform '@allele = split /:/, {{allele}} =~ s/\D$$//r; push_output({ locus => {{locus}}, prefix => $$_ }) for join(":", @allele[0,1]), $$allele[0]' \
		| $(recs) collate -k locus,prefix \
		| $(recs) sort -k locus,prefix \
		| $(recs) eval 'join ";", {{locus}}, "", {{prefix}}' \
		> $@.generics
	# Filter out generated genotypes which are already in the official dataset
	sort $@ $@.generics | uniq -d | sort - $@.generics | uniq -u >> $@
	rm $@.generics

new-genotypes-deploy.sql: generate-sql hla_nom_filtered.txt
	carton exec -- perl $^ --new --output new-genotypes

new-genotypes-revert.sql new-genotypes-verify.sql: new-genotypes-deploy.sql

everything-deploy.sql: generate-sql hla_nom_filtered.txt hla_nom_g.txt hla_nom_p.txt
	carton exec -- perl $^ --all --output everything

clean:
	rm -vf hla_nom{,_g,_p,_filtered}.txt {new-{ambiguity-groups,genotypes},everything}-{deploy,revert,verify}.sql
