-- Deploy retire-delta-schema

BEGIN;

ALTER TABLE delta.derivation
  SET SCHEMA viroserve;
ALTER TABLE viroserve.derivation
  DROP CONSTRAINT derivation_protocol_id_fkey;
ALTER TABLE viroserve.derivation
  RENAME COLUMN protocol_id TO derivation_protocol_id;

ALTER TABLE delta.protocol_output
  SET SCHEMA viroserve;
ALTER TABLE viroserve.protocol_output
  DROP CONSTRAINT protocol_output_protocol_id_fkey;
ALTER TABLE viroserve.protocol_output
  RENAME COLUMN protocol_id TO derivation_protocol_id;

ALTER TABLE delta.protocol
  RENAME TO derivation_protocol;
ALTER TABLE delta.derivation_protocol
  RENAME COLUMN protocol_id TO derivation_protocol_id;
ALTER INDEX delta.protocol_pkey RENAME TO derivation_protocol_pkey;
ALTER INDEX delta.protocol_name_key RENAME TO derivation_protocol_name_key;

ALTER SEQUENCE delta.protocol_protocol_id_seq
  RENAME TO derivation_protocol_derivation_protocol_id_seq;

ALTER TABLE delta.derivation_protocol
  SET SCHEMA viroserve;

ALTER TABLE viroserve.derivation
  ADD FOREIGN KEY (derivation_protocol_id)
       REFERENCES viroserve.derivation_protocol(derivation_protocol_id);

ALTER TABLE viroserve.protocol_output
  ADD FOREIGN KEY (derivation_protocol_id)
       REFERENCES viroserve.derivation_protocol(derivation_protocol_id);

DROP SCHEMA delta;

COMMIT;
