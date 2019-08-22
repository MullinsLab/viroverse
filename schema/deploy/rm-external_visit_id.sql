-- Deploy rm-external_visit_id

BEGIN;

ALTER TABLE viroserve.visit DROP COLUMN external_visit_id;

COMMIT;
