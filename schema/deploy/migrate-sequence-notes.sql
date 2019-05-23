-- Deploy migrate-sequence-notes

BEGIN;

SET search_path TO viroserve;

CREATE TABLE na_sequence_note (
    na_sequence_note_id SERIAL PRIMARY KEY,
    na_sequence_id INTEGER NOT NULL,
    na_sequence_revision INTEGER NOT NULL,
    scientist_id INTEGER NOT NULL REFERENCES scientist(scientist_id),
    body TEXT NOT NULL,
    time_created TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),

    FOREIGN KEY (na_sequence_id, na_sequence_revision) REFERENCES
        na_sequence(na_sequence_id, na_sequence_revision)
);

/* Note: the 'America/Los_Angeles' time zone is hardcoded below due to the need
 * to migrate existing data within the Mullins Lab. At this point we don't
 * believe any other installations of Viroverse exist. All future deployments
 * will contain no data when initially set up, so the data migration will be
 * a no-op, and thus the timezone here won't matter.
 */
INSERT INTO na_sequence_note
      (na_sequence_id, na_sequence_revision, scientist_id, body, time_created)
SELECT na_sequence_id, na_sequence_revision, coalesce(scientist_id, 0), note,
           timezone('America/Los_Angeles', entered_date + time '00:00')
     FROM na_sequence WHERE note IS NOT NULL;

INSERT INTO na_sequence_note
      (na_sequence_id, na_sequence_revision, scientist_id, body, time_created)
SELECT na_sequence_id, na_sequence_revision, notes.scientist_id, notes.note,
           timezone('America/Los_Angeles', notes.date_added + time '00:00')
  FROM notes JOIN na_sequence USING (vv_uid);

DELETE FROM notes
      USING na_sequence
      WHERE notes.vv_uid = na_sequence.vv_uid;

ALTER TABLE na_sequence
    DROP COLUMN note,
    DROP COLUMN vv_uid;

GRANT SELECT ON na_sequence_note TO viroverse_r;
GRANT ALL    ON na_sequence_note TO viroverse_w;
GRANT ALL    ON na_sequence_note_na_sequence_note_id_seq TO viroverse_w;

COMMIT;
