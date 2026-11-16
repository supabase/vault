CREATE ROLE bob login password 'bob';

CREATE EXTENSION plpgsql_check;
CREATE EXTENSION supabase_vault;

GRANT USAGE ON SCHEMA vault TO bob WITH GRANT OPTION;
GRANT SELECT ON vault.secrets, vault.decrypted_secrets TO bob WITH GRANT OPTION;
GRANT INSERT ON vault.secrets TO bob;
GRANT UPDATE ON vault.secrets TO bob;
GRANT DELETE ON vault.secrets TO bob;
