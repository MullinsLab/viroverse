-- Deploy assays

BEGIN;

SET search_path TO viroserve;

/* While we're here, drop the sample_id column from lab_result_num and
   lab_result_cat. In Mullins Lab production, it only contains data due to
   conservatism. The association of lab results with samples has long been
   deprecated and we've got no way of knowing if any of the retained data is
   meaningful. */

ALTER TABLE lab_result_num
    DROP COLUMN sample_id;

ALTER TABLE lab_result_cat
    DROP COLUMN sample_id;

CREATE TABLE numeric_assay_protocol (
    numeric_assay_protocol_id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    unit_id INTEGER REFERENCES unit(unit_id) NOT NULL
);

CREATE TABLE numeric_assay_result (
    numeric_assay_result_id SERIAL PRIMARY KEY,
    numeric_assay_protocol_id INTEGER
        REFERENCES numeric_assay_protocol(numeric_assay_protocol_id) NOT NULL,
    sample_id INTEGER REFERENCES sample(sample_id) NOT NULL,
    scientist_id INTEGER REFERENCES scientist(scientist_id) NOT NULL,

    value NUMERIC,

    uri TEXT,
    note TEXT,
    date_completed DATE,
    time_created TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

GRANT SELECT ON numeric_assay_result TO :ro_user;
GRANT ALL    ON numeric_assay_result TO :rw_user;
GRANT ALL    ON viroserve.numeric_assay_result_numeric_assay_result_id_seq
    TO :rw_user;

GRANT SELECT ON numeric_assay_protocol TO :ro_user;
GRANT ALL    ON numeric_assay_protocol TO :rw_user;
GRANT ALL    ON viroserve.numeric_assay_protocol_numeric_assay_protocol_id_seq
    TO :rw_user;


COMMIT;
