-- Verify primer_search_refresh

BEGIN;

SELECT viroserve.refresh_primer_search();

ROLLBACK;
