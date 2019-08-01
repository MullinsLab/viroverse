-- Verify migrate-sequence-notes

BEGIN;

SELECT
    1/pg_catalog.has_table_privilege(
        :'rw_user', 'viroserve.na_sequence_note', 'INSERT')::int +
    1/pg_catalog.has_table_privilege(
        :'ro_user', 'viroserve.na_sequence_note', 'SELECT')::int;

ROLLBACK;
