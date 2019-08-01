-- Verify assays

BEGIN;

SELECT
    1/pg_catalog.has_table_privilege(
        :'rw_user', 'viroserve.numeric_assay_result', 'INSERT')::int +
    1/pg_catalog.has_table_privilege(
        :'ro_user', 'viroserve.numeric_assay_result', 'SELECT')::int +
    1/pg_catalog.has_table_privilege(
        :'rw_user', 'viroserve.numeric_assay_protocol', 'INSERT')::int +
    1/pg_catalog.has_table_privilege(
        :'ro_user', 'viroserve.numeric_assay_protocol', 'SELECT')::int;

ROLLBACK;
