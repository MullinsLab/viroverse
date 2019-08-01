-- Verify primer_position_search

BEGIN;

SELECT
    1/pg_catalog.has_table_privilege(:'rw_user', 'viroserve.primer_search', 'SELECT')::int +
    1/pg_catalog.has_table_privilege(:'ro_user', 'viroserve.primer_search', 'SELECT')::int;

ROLLBACK;
