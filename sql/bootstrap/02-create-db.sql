-- This script creates a new database and adjusts ownership.  It must be run as
-- a Pg superuser (usually "postgres").

\set ON_ERROR_STOP on

CREATE DATABASE viroverse
    WITH OWNER vverse_admin
         ENCODING 'UTF-8'
         TEMPLATE template0;

-- Switch to the new database
\c viroverse

-- The default public schema from template0 is owned by the default Pg
-- superuser and we want to own it so our owner has full control after this.
ALTER SCHEMA public OWNER TO vverse_admin;

-- This works iff we're the superuser or the owner of the public schema.
-- Otherwise, it quietly does nothing!
REVOKE CREATE ON SCHEMA public FROM PUBLIC;
