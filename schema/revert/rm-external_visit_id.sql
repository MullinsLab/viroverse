-- Revert rm-external_visit_id

BEGIN;

ALTER TABLE viroserve.visit
    ADD COLUMN external_visit_id varchar(20);

COMMIT;
