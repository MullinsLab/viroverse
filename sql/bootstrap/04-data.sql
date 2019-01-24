-- Additives: common
COPY viroserve.additive (name) FROM stdin;
ACD
EDTA
Heparin
Guanidium
clot activator
\.


-- Organism: example/common
COPY viroserve.organism (name) FROM stdin;
HIV-1
human
\.


-- Tissues: example/common
COPY viroserve.tissue_type (name) FROM stdin;
lab strain
blood
plasma
PBMC
Leukapheresed cells
\.


-- Alignment method: used by pairwise sequence aligner
COPY viroserve.alignment_method (name) FROM stdin;
needle
\.


-- Chromat type: required/common
COPY viroserve.chromat_type (ident_string, name) FROM stdin;
ABIF	ABI
.scf	SCF
\.


-- Extract type: required/common
COPY viroserve.extract_type (name) FROM stdin;
DNA
RNA
\.


-- Genome region: required/common to HIV-1
COPY viroserve.genome_region (name, base_start, base_end, base_range, reading_frame) FROM stdin;
5LTR	1	634	[1,635)	1
gag	790	2292	[790,2293)	1
p17	790	1186	[790,1187)	1
p24	1186	1879	[1186,1880)	1
p2	1879	1921	[1879,1922)	1
p7	1921	2086	[1921,2087)	1
p1	2086	2134	[2086,2135)	1
p6	2134	2292	[2134,2293)	1
pol	2085	5096	[2085,5097)	3
prot	2253	2550	[2253,2551)	3
p51rt	2550	3870	[2550,3871)	3
p15	3870	4230	[3870,4231)	3
p31int	4230	5096	[4230,5097)	3
vif	5041	5619	[5041,5620)	1
vpr	5559	5850	[5559,5851)	3
tat1	5831	6045	[5831,6046)	2
tat2	8379	8469	[8379,8470)	1
rev1	5970	6045	[5970,6046)	3
rev2	8379	8653	[8379,8654)	2
vpu	6062	6310	[6062,6311)	2
env	6225	8795	[6225,8796)	3
gp120	6225	7758	[6225,7759)	3
gp41	7758	8795	[7758,8796)	3
v1	6615	6692	[6615,6693)	3
v2	6693	6812	[6693,6813)	3
v3	7110	7217	[7110,7218)	3
v4	7377	7478	[7377,7479)	3
v5	7602	7634	[7602,7635)	3
nef	8797	9417	[8797,9418)	1
3LTR	9086	9719	[9086,9720)	2
\.


-- ARV classes: common
COPY viroserve.arv_class (arv_class_id, name, abbreviation) FROM stdin;
1	Nucleoside Reverse Transcriptase Inhibitor	NRTI
2	Non-Nucleoside Reverse Transcriptase Inhibitor	NNRTI
3	Protease Inhibitor	PI
4	Entry Inhibitor	EI
5	Integrase Inhibitor	INSTI
6	Non-ARV booster	Non-ARV booster
\.

DO $$ BEGIN PERFORM pg_catalog.setval('viroserve.arv_class_arv_class_id_seq', (SELECT max(arv_class_id) FROM viroserve.arv_class), true); END $$;


-- Medication (ART): common HIV-1 anti-retrovirals
--   XXX TODO: Ideally these wouldn't hardcode an arv_class_id but would look it
--   up by abbreviation (NRTI, PI, INSTI, etc.)
COPY viroserve.medication (name, abbreviation, arv_class_id) FROM stdin;
Zidovudine	AZT	1
Lamivudine	3TC	1
Didanosine	DDI	1
Zalcitabine	DDC	1
Stavudine	D4T	1
Abacavir	ABC	1
Adefovir	ADE	1
Tenofovir	TDF	1
Emtricitabine	FTC	1
Nevirapine	NVP	2
Delavirdine	DLV	2
Efavirenz	EFV	2
Etravirine	ETR	2
Rilpivirine	RPV	2
Indinavir	IDV	3
Saquinavir	SQV	3
Nelfinavir	NFV	3
Ritonavir	RTV	3
Amprenavir	APV	3
Tipranavir	TPV	3
Atazanavir	ATV	3
Darunavir	DRV	3
Fosamprenavir	FPV	3
Lopinavir	LPV	3
Enfuvirtide	ENF	4
AMD-3100	AMD	4
Maraviroc	MVC	4
Elvitegravir	EVG	5
Raltegravir	RAL	5
Dolutegravir	DTG	5
Tenofovir Alafenamide	TAF	1
Cobicistat	COBI	6
\.


-- Generic protocol type: required
COPY viroserve.protocol_type (name) FROM stdin;
extraction
pcr
purification
concentration
cloning
bisulfite_conversion
\.


-- Sample type (ugh): required
COPY viroserve.sample_type (name) FROM stdin;
synthetic
cells
RNA
\.


-- Sequence type
COPY viroserve.sequence_type (name) FROM stdin;
Genomic
Bisulfite
Integration site
\.


-- Units: required/common
COPY viroserve.unit (unit_id, name) FROM stdin;
1	10^6 cells
2	copies/ml
3	dil
4	g/dl
5	IU/l
6	mEq/l
7	mg
8	mg/dl
9	microu/ml
10	mil/ul
11	ml
12	mm
13	ng
14	ng/ul
15	pellet
16	percent
17	pg
18	thousand/ul
19	ul
\.

DO $$ BEGIN PERFORM pg_catalog.setval('viroserve.unit_unit_id_seq', (SELECT max(unit_id) FROM viroserve.unit), true); END $$;


-- Scientist: required
COPY viroserve.scientist (scientist_id, name, role) FROM stdin;
0	Viroverse itself	retired
\.

DO $$ BEGIN PERFORM pg_catalog.setval('viroserve.scientist_scientist_id_seq', (SELECT max(scientist_id) + 1 FROM viroserve.scientist), false); END $$;


-- Scientist group: required (to create scientists from web)
COPY viroserve.scientist_group (name, creating_scientist_id, display) FROM stdin;
Default	0	t
\.


-- Categorical lab types: example/common
COPY viroserve.lab_result_cat_type (lab_result_cat_type_id, name) FROM stdin;
1	Fiebig stage
\.

DO $$ BEGIN PERFORM pg_catalog.setval('viroserve.lab_result_cat_type_lab_result_cat_type_id_seq', (SELECT max(lab_result_cat_type_id) + 1 FROM viroserve.lab_result_cat_type), false); END $$;


-- XXX TODO: Ideally these wouldn't hardcode a type id but would look up it by name.
COPY viroserve.lab_result_cat_value (lab_result_cat_type_id, name) FROM stdin;
1	pre I
1	I
1	I/II
1	II
1	III
1	IV
1	V
1	V/VI
1	VI
\.


-- Numeric lab types: example/common
--   XXX TODO: Ideally these wouldn't hardcode a unit_id but would look it up
--   by name (copies/ml).
COPY viroserve.lab_result_num_type (name, unit_id, normal_min) FROM stdin;
viral load (Chiron Quantiplex HIV-1 bDNA v1.0)	2	10000
viral load (Chiron Quantiplex HIV-1 bDNA v2.0)	2	500
viral load (Chiron Quantiplex HIV-1 bDNA v3.0)	2	50
viral load (Roche Amplicor HIV-1 Monitor v1.5)	2	400
viral load (Roche Amplicor HIV-1 Monitor Ultra-sensitive v1.5)	2	50
viral load (Roche Cobas TaqMan HIV-1 v1.0)	2	48
viral load (Roche Cobas TaqMan HIV-1 v2.0)	2	20
viral load (Abbott RealTime HIV-1)	2	40
viral load	2	\N
\.
