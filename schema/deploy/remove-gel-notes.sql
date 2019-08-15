-- Deploy viroverse-public:remove-gel-notes to pg

BEGIN;

SET search_path TO viroserve;

ALTER TABLE gel DROP COLUMN notes;

COMMIT;
