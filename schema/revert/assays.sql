-- Revert assays

BEGIN;

ALTER TABLE viroserve.lab_result_num
    ADD COLUMN sample_id INTEGER REFERENCES viroserve.sample(sample_id);

ALTER TABLE viroserve.lab_result_cat
    ADD COLUMN sample_id INTEGER REFERENCES viroserve.sample(sample_id);

DROP TABLE viroserve.numeric_assay_result;
DROP TABLE viroserve.numeric_assay_protocol;

COMMIT;
