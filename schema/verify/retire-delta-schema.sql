-- Verify retire-delta-schema

BEGIN;

SELECT
    1/pg_catalog.has_table_privilege(
        'viroverse_w', 'viroserve.derivation_protocol', 'INSERT')::int +
    1/pg_catalog.has_table_privilege(
        'viroverse_r', 'viroserve.derivation_protocol', 'SELECT')::int;

SELECT
    1/pg_catalog.has_table_privilege(
        'viroverse_w', 'viroserve.derivation', 'INSERT')::int +
    1/pg_catalog.has_table_privilege(
        'viroverse_r', 'viroserve.derivation', 'SELECT')::int;

SELECT
    1/pg_catalog.has_table_privilege(
        'viroverse_w', 'viroserve.protocol_output', 'INSERT')::int +
    1/pg_catalog.has_table_privilege(
        'viroverse_r', 'viroserve.protocol_output', 'SELECT')::int;

ROLLBACK;
