-- Verify pacbio_pools

BEGIN;

SELECT
    1/pg_catalog.has_table_privilege(:'rw_user', 'viroserve.pacbio_pool', 'SELECT')::int +
    1/pg_catalog.has_table_privilege(:'ro_user', 'viroserve.pacbio_pool', 'SELECT')::int;

ROLLBACK;
