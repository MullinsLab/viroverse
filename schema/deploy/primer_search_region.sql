-- Deploy viroverse-public:primer_search_region to pg

BEGIN;

SET search_path TO viroserve;

DROP FUNCTION viroserve.refresh_primer_search();
DROP MATERIALIZED VIEW primer_search;

CREATE MATERIALIZED VIEW viroserve.primer_search AS
SELECT
    primer.primer_id AS primer_id,
    primer.name AS name,
    primer.sequence AS sequence,
    primer.orientation AS orientation,
    primer.lab_common AS lab_common,
    primer.notes AS notes,
    primer.date_added AS date_added,
    organism.name AS organism,
    CASE primer.orientation
        WHEN 'F' THEN
            array_agg(DISTINCT primer_position.hxb2_end)
        ELSE
            array_agg(DISTINCT primer_position.hxb2_start)
    END AS positions,
    array_agg(DISTINCT genome_region.name) AS regions
FROM primer
LEFT JOIN organism USING (organism_id)
LEFT JOIN primer_position USING (primer_id)
LEFT JOIN genome_region ON (
    (primer.orientation = 'F'
        AND genome_region.base_start <= primer_position.hxb2_end
        AND genome_region.base_end >= primer_position.hxb2_end)
    OR (primer.orientation = 'R'
        AND genome_region.base_start <= primer_position.hxb2_start
        AND genome_region.base_end >= primer_position.hxb2_start))
GROUP BY primer.primer_id, organism.name
;

CREATE UNIQUE INDEX primer_search_primer_id_idx   ON primer_search USING btree(primer_id);
CREATE        INDEX primer_search_name_idx        ON primer_search USING btree(name);
CREATE        INDEX primer_search_sequence_idx    ON primer_search USING btree(sequence);
CREATE        INDEX primer_search_orientation_idx ON primer_search USING btree(orientation);
CREATE        INDEX primer_search_date_added_idx  ON primer_search USING btree(date_added);
CREATE        INDEX primer_search_organism_idx    ON primer_search USING btree(organism);

CREATE FUNCTION viroserve.refresh_primer_search() RETURNS void
    LANGUAGE sql SECURITY DEFINER
    AS $$
        REFRESH MATERIALIZED VIEW CONCURRENTLY viroserve.primer_search;
    $$;

GRANT EXECUTE ON FUNCTION viroserve.refresh_primer_search() TO :rw_user;
REVOKE EXECUTE ON FUNCTION viroserve.refresh_primer_search() FROM PUBLIC;


GRANT SELECT ON primer_search TO :ro_user;
GRANT SELECT ON primer_search TO :rw_user;


COMMIT;
