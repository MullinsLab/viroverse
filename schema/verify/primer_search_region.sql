-- Verify viroverse-public:primer_search_region on pg

BEGIN;

SELECT
    1/pg_catalog.has_table_privilege(:'rw_user', 'viroserve.primer_search', 'SELECT')::int +
    1/pg_catalog.has_table_privilege(:'ro_user', 'viroserve.primer_search', 'SELECT')::int;

SELECT viroserve.refresh_primer_search();


ROLLBACK;
