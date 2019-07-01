-- Verify retire-delta-schema

BEGIN;

SELECT
    1/pg_catalog.has_table_privilege(
        :'rw_user', 'viroserve.derivation_protocol', 'INSERT')::int +
    1/pg_catalog.has_table_privilege(
        :'ro_user', 'viroserve.derivation_protocol', 'SELECT')::int;

SELECT
    1/pg_catalog.has_table_privilege(
        :'rw_user', 'viroserve.derivation', 'INSERT')::int +
    1/pg_catalog.has_table_privilege(
        :'ro_user', 'viroserve.derivation', 'SELECT')::int;

SELECT
    1/pg_catalog.has_table_privilege(
        :'rw_user', 'viroserve.protocol_output', 'INSERT')::int +
    1/pg_catalog.has_table_privilege(
        :'ro_user', 'viroserve.protocol_output', 'SELECT')::int;

ROLLBACK;
