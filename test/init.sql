CREATE ROLE bob login password 'bob';

CREATE EXTENSION plpgsql_check;
CREATE EXTENSION pgcrypto;
CREATE EXTENSION supabase_vault CASCADE;

GRANT USAGE ON SCHEMA vault TO bob WITH GRANT OPTION;
GRANT SELECT ON vault.secrets, vault.decrypted_secrets TO bob WITH GRANT OPTION;
GRANT EXECUTE ON FUNCTION
  vault.create_secret,
  vault.update_secret,
  vault._get_secret_key
TO bob WITH GRANT OPTION;
