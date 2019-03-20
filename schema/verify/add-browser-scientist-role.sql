-- Verify add-browser-scientist-role

BEGIN;

INSERT INTO viroserve.scientist (username,        role)
                         VALUES ('sqitch-verify', 'browser');

ROLLBACK;
