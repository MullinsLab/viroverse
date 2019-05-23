-- Verify migrate-sequence-notes

BEGIN;

SELECT
    1/pg_catalog.has_table_privilege(
        'viroverse_w', 'viroserve.na_sequence_note', 'INSERT')::int +
    1/pg_catalog.has_table_privilege(
        'viroverse_r', 'viroserve.na_sequence_note', 'SELECT')::int;

ROLLBACK;
