-- Revert add-browser-scientist-role

BEGIN;

SET search_path TO viroserve;

ALTER DOMAIN scientist_role SET DEFAULT 'scientist';
ALTER DOMAIN scientist_role DROP CONSTRAINT valid_role_name;
ALTER DOMAIN scientist_role ADD CONSTRAINT valid_role_name CHECK (
    VALUE IN ('scientist', 'supervisor', 'admin', 'retired')
);

COMMIT;
