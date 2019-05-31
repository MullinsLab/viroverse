-- Revert migrate-sequence-notes

BEGIN;

SET search_path TO viroserve;

ALTER TABLE na_sequence
    ADD COLUMN vv_uid integer NOT NULL DEFAULT nextval('viroserve.vv_uid');

INSERT INTO notes (vv_uid, scientist_id, note, date_added)
SELECT s.vv_uid, n.scientist_id, n.body, n.time_created::date
  FROM na_sequence_note n
  JOIN na_sequence s USING (na_sequence_id, na_sequence_revision);

DROP TABLE viroserve.na_sequence_note;

COMMIT;
