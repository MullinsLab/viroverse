-- Revert viroverse-public:remove-gel-notes from pg

BEGIN;

SET search_path TO viroserve;

ALTER TABLE gel ADD COLUMN notes character varying(255);

COMMIT;
