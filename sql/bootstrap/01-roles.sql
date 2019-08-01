-- This script creates three roles with different privilege levels, although
-- does not configure how those roles may be accessed by clients.  Configuring
-- authentication for these users is complex and highly situation-dependent,
-- and therefore left as an exercise for the reader:
--
--   http://www.postgresql.org/docs/current/static/client-authentication.html
--
-- Note that you if plan to use password authentication, you'll need to run
--
--   ALTER USER ... WITH PASSWORD '...';
--
-- manually after this script to add a password for each user.
--
-- This must be run as a Pg superuser (usually "postgres").

\set ON_ERROR_STOP on

BEGIN;

CREATE USER :owner;
CREATE USER :ro_user;
CREATE USER :rw_user;

COMMIT;
