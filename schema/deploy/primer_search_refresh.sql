-- Deploy primer_search_refresh

BEGIN;

SET search_path TO viroserve;

DROP INDEX primer_search_primer_id_idx;
CREATE UNIQUE INDEX primer_search_primer_id_idx ON primer_search USING btree(primer_id);

COMMIT;
