-- Revert add-sequencing-run

BEGIN;

SET search_path TO viroserve;

DROP TABLE sequencing_run_pcr_product;
DROP TABLE sequencing_run;

COMMIT;
