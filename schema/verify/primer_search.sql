-- Verify primer_position_search

BEGIN;

SELECT
    1/pg_catalog.has_table_privilege('viroverse_w', 'viroserve.primer_search', 'SELECT')::int +
    1/pg_catalog.has_table_privilege('viroverse_r', 'viroserve.primer_search', 'SELECT')::int;

ROLLBACK;
