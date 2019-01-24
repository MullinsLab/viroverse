-- Setup Pg roles and ownerships for new vverse_admin user used by sqitch.
-- This lets us not use a Pg superuser.
--
-- Requirement: A vverse_admin database user.
--
--      createuser vverse_admin
-- or:  CREATE ROLE vverse_admin WITH LOGIN PASSWORD '...';
--

BEGIN;

ALTER DATABASE :DBNAME OWNER TO vverse_admin;

-- REASSIGN OWNED doesn't work for us because we have objects owned by postgres.
-- From http://stackoverflow.com/questions/1348126/modify-owner-on-all-tables-simultaneously-in-postgresql
CREATE FUNCTION exec(text) returns text language plpgsql volatile
  AS $f$
    BEGIN
      EXECUTE $1;
      RETURN $1;
    END;
$f$;

-- Tables, views, and sequences
SELECT exec('ALTER TABLE ' || quote_ident(s.nspname) || '.' ||
            quote_ident(s.relname) || ' OWNER TO vverse_admin')
  FROM (SELECT nspname, relname
          FROM pg_class c JOIN pg_namespace n ON (c.relnamespace = n.oid) 
         WHERE nspname NOT LIKE E'pg\\_%' AND 
               nspname <> 'information_schema' AND 
               relkind IN ('r','S','v') ORDER BY relkind = 'S') s;

-- Schemas
SELECT exec('ALTER SCHEMA ' || quote_ident(s.nspname) || ' OWNER TO vverse_admin')
  FROM (SELECT nspname
          FROM pg_namespace
         WHERE nspname NOT LIKE E'pg\\_%' AND 
               nspname <> 'information_schema' ORDER BY nspname) s;

DROP FUNCTION exec(text);

COMMIT;
