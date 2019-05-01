-- Deploy add-sequencing-run

BEGIN;

SET search_path TO viroserve;

CREATE TABLE sequencing_run (
    sequencing_run_id integer PRIMARY KEY,
    name text NOT NULL,
    note text,
    scientist_id integer REFERENCES scientist(scientist_id) NOT NULL,
    date_submitted date,
    date_completed date,
    date_entered date NOT NULL
);

CREATE TABLE sequencing_run_pcr_product (
    sequencing_run_id integer REFERENCES sequencing_run(sequencing_run_id) NOT NULL,
    pcr_product_id integer REFERENCES pcr_product(pcr_product_id) NOT NULL,
    UNIQUE(sequencing_run_id, pcr_product_id)
);

COMMIT;
