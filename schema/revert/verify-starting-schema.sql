-- Revert verify-starting-schema

BEGIN;

-- Does nothing; this "migration" only exists to run the verify step

SELECT 1;

COMMIT;
