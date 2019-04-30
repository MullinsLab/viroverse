-- Revert retire-delta-schema

BEGIN;


CREATE SCHEMA delta;
GRANT USAGE ON SCHEMA delta TO viroverse_w, viroverse_r;

ALTER TABLE viroserve.protocol_output
  DROP CONSTRAINT protocol_output_derivation_protocol_id_fkey;

ALTER TABLE viroserve.derivation
  DROP CONSTRAINT derivation_derivation_protocol_id_fkey;

ALTER TABLE viroserve.derivation_protocol
  SET SCHEMA delta;

ALTER TABLE delta.derivation_protocol
  RENAME TO protocol;

ALTER SEQUENCE delta.derivation_protocol_derivation_protocol_id_seq
  RENAME TO protocol_protocol_id_seq;
ALTER TABLE delta.protocol
  RENAME COLUMN derivation_protocol_id TO protocol_id;
ALTER INDEX delta.derivation_protocol_pkey RENAME TO protocol_pkey;
ALTER INDEX delta.derivation_protocol_name_key RENAME TO protocol_name_key;

ALTER TABLE viroserve.derivation
  RENAME COLUMN derivation_protocol_id TO protocol_id;
ALTER TABLE viroserve.derivation
  SET SCHEMA delta;
ALTER TABLE delta.derivation
  ADD FOREIGN KEY (protocol_id)
       REFERENCES delta.protocol(protocol_id);

ALTER TABLE viroserve.protocol_output
  RENAME COLUMN derivation_protocol_id TO protocol_id;
ALTER TABLE viroserve.protocol_output
  SET SCHEMA delta;
ALTER TABLE delta.protocol_output
  ADD FOREIGN KEY (protocol_id)
       REFERENCES delta.protocol(protocol_id);


COMMIT;
