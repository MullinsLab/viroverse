-- Verify viroverse-public:remove-gel-notes on pg

BEGIN;

SET search_path TO viroserve;

SELECT
    1/(1-(SELECT count(column_name) FROM information_schema.columns WHERE table_name='gel' and column_name='notes'));


ROLLBACK;
