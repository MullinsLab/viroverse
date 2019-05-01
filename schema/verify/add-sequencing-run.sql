-- Verify add-sequencing-run

BEGIN;

SELECT 1/(count(*) = 1)::int
  FROM information_schema.tables
 WHERE table_schema = 'viroserve'
   AND table_name   = 'sequencing_run';

SELECT 1/(count(*) = 1)::int
  FROM information_schema.tables
 WHERE table_schema = 'viroserve'
   AND table_name   = 'sequencing_run_pcr_product';

ROLLBACK;
