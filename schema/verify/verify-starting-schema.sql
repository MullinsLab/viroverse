-- Verify verify-starting-schema

BEGIN;

    /* Check that all the tables we expect to exist after bootstrapping do exist
     * and have required permissions, and that a few tables we specifically
     * expect to not exist, based on some of the last pre-publication phases of
     * development in the Mullins Lab, do not exist. This is here as a sanity
     * check to improve the chances that no sqitch changes are run
     * against a database that is in an unexpected state.
     */

CREATE FUNCTION pg_temp.verify_table(table_name text) RETURNS INTEGER LANGUAGE sql AS $$
    SELECT
    1/pg_catalog.has_table_privilege(
        'viroverse_w', table_name, 'INSERT')::int +
    1/pg_catalog.has_table_privilege(
        'viroverse_r', table_name, 'SELECT')::int;
$$;

CREATE FUNCTION pg_temp.verify_nonexistent_table(a_schema_name text, a_table_name text) RETURNS INTEGER LANGUAGE sql AS $$
SELECT 1/CASE WHEN count(*) = 0 THEN 1 ELSE 0 END
FROM information_schema.tables
WHERE table_schema = a_schema_name
AND table_name = a_table_name;
$$;

SELECT pg_temp.verify_table('delta.derivation');
SELECT pg_temp.verify_table('delta.protocol');
SELECT pg_temp.verify_table('delta.protocol_output');
SELECT pg_temp.verify_table('epitope.blcl');
SELECT pg_temp.verify_table('epitope.epitope');
SELECT pg_temp.verify_table('epitope.epitope_mutant');
SELECT pg_temp.verify_table('epitope.epitope_sequence');
SELECT pg_temp.verify_table('epitope.epitope_source');
SELECT pg_temp.verify_table('epitope.experiment');
SELECT pg_temp.verify_table('epitope.gene');
SELECT pg_temp.verify_table('epitope.hla');
SELECT pg_temp.verify_table('epitope.hla_pept');
SELECT pg_temp.verify_table('epitope.hla_response');
SELECT pg_temp.verify_table('epitope.measurement');
SELECT pg_temp.verify_table('epitope.mutant');
SELECT pg_temp.verify_table('epitope.origin');
SELECT pg_temp.verify_table('epitope.origin_peptide');
SELECT pg_temp.verify_table('epitope.peptide');
SELECT pg_temp.verify_table('epitope.pept_response');
SELECT pg_temp.verify_table('epitope.pool');
SELECT pg_temp.verify_table('epitope.pool_pept');
SELECT pg_temp.verify_table('epitope.pool_response');
SELECT pg_temp.verify_table('epitope.reading');
SELECT pg_temp.verify_table('epitope.titration');
SELECT pg_temp.verify_table('epitope.titration_conc');
SELECT pg_temp.verify_table('viroserve.additive');
SELECT pg_temp.verify_table('viroserve.alignment');
SELECT pg_temp.verify_table('viroserve.aliquot');
SELECT pg_temp.verify_table('viroserve.arv_class');
SELECT pg_temp.verify_table('viroserve.bisulfite_converted_dna');
SELECT pg_temp.verify_table('viroserve.chromat');
SELECT pg_temp.verify_table('viroserve.chromat_na_sequence');
SELECT pg_temp.verify_table('viroserve.chromat_type');
SELECT pg_temp.verify_table('viroserve.clone');
SELECT pg_temp.verify_table('viroserve.cohort');
SELECT pg_temp.verify_table('viroserve.copy_number');
SELECT pg_temp.verify_table('viroserve.copy_number_gel_lane');
SELECT pg_temp.verify_table('viroserve.enzyme');
SELECT pg_temp.verify_table('viroserve.extraction');
SELECT pg_temp.verify_table('viroserve.extract_type');
SELECT pg_temp.verify_table('viroserve.gel');
SELECT pg_temp.verify_table('viroserve.gel_lane');
SELECT pg_temp.verify_table('viroserve.genome_region');
SELECT pg_temp.verify_table('viroserve.hla_genotype');
SELECT pg_temp.verify_table('viroserve.import_job');
SELECT pg_temp.verify_table('viroserve.infection');
SELECT pg_temp.verify_table('viroserve.lab_result_cat');
SELECT pg_temp.verify_table('viroserve.lab_result_cat_type');
SELECT pg_temp.verify_table('viroserve.lab_result_cat_type_group');
SELECT pg_temp.verify_table('viroserve.lab_result_cat_value');
SELECT pg_temp.verify_table('viroserve.lab_result_group');
SELECT pg_temp.verify_table('viroserve.lab_result_num');
SELECT pg_temp.verify_table('viroserve.lab_result_num_type');
SELECT pg_temp.verify_table('viroserve.lab_result_num_type_group');
SELECT pg_temp.verify_table('viroserve.location');
SELECT pg_temp.verify_table('viroserve.medication');
SELECT pg_temp.verify_table('viroserve.na_sequence');
SELECT pg_temp.verify_table('viroserve.na_sequence_alignment');
SELECT pg_temp.verify_table('viroserve.na_sequence_alignment_pairwise');
SELECT pg_temp.verify_table('viroserve.notes');
SELECT pg_temp.verify_table('viroserve.organism');
SELECT pg_temp.verify_table('viroserve.patient');
SELECT pg_temp.verify_table('viroserve.patient_alias');
SELECT pg_temp.verify_table('viroserve.patient_cohort');
SELECT pg_temp.verify_table('viroserve.patient_group');
SELECT pg_temp.verify_table('viroserve.patient_hla_genotype');
SELECT pg_temp.verify_table('viroserve.patient_medication');
SELECT pg_temp.verify_table('viroserve.patient_patient_group');
SELECT pg_temp.verify_table('viroserve.pcr_cleanup');
SELECT pg_temp.verify_table('viroserve.pcr_pool');
SELECT pg_temp.verify_table('viroserve.pcr_pool_pcr_product');
SELECT pg_temp.verify_table('viroserve.pcr_product');
SELECT pg_temp.verify_table('viroserve.pcr_product_primer');
SELECT pg_temp.verify_table('viroserve.pcr_template');
SELECT pg_temp.verify_table('viroserve.primer');
SELECT pg_temp.verify_table('viroserve.primer_position');
SELECT pg_temp.verify_table('viroserve.project');
SELECT pg_temp.verify_table('viroserve.project_materials');
SELECT pg_temp.verify_table('viroserve.protocol');
SELECT pg_temp.verify_table('viroserve.rt_primer');
SELECT pg_temp.verify_table('viroserve.rt_product');
SELECT pg_temp.verify_table('viroserve.sample');
SELECT pg_temp.verify_table('viroserve.sample_note');
SELECT pg_temp.verify_table('viroserve.sample_type');
SELECT pg_temp.verify_table('viroserve.scientist');
SELECT pg_temp.verify_table('viroserve.scientist_group');
SELECT pg_temp.verify_table('viroserve.scientist_scientist_group');
SELECT pg_temp.verify_table('viroserve.sequence_type');
SELECT pg_temp.verify_table('viroserve.tissue_type');
SELECT pg_temp.verify_table('viroserve.unit');
SELECT pg_temp.verify_table('viroserve.visit');

SELECT pg_temp.verify_nonexistent_table('viroserve', 'competent_cells');
SELECT pg_temp.verify_nonexistent_table('viroserve', 'vector');
SELECT pg_temp.verify_nonexistent_table('viroserve', 'digestion_restriction_enzyme');
SELECT pg_temp.verify_nonexistent_table('viroserve', 'restriction_enzyme');
SELECT pg_temp.verify_nonexistent_table('viroserve', 'digestion');
SELECT pg_temp.verify_nonexistent_table('viroserve', 'plasmid_prep');

ROLLBACK;
