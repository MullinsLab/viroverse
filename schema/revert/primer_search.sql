-- Revert primer_position_search

SET search_path TO viroserve;

BEGIN;

ALTER TABLE primer ADD COLUMN some_number INTEGER;

DROP FUNCTION refresh_primer_search();
DROP MATERIALIZED VIEW primer_search;

COMMIT;
