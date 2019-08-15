-- Revert pacbio_pools

BEGIN;

DROP VIEW viroserve.pacbio_pool;

COMMIT;
