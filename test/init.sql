CREATE ROLE bob login password 'bob';

CREATE EXTENSION IF NOT EXISTS pgtap;
CREATE EXTENSION supabase_vault CASCADE;

GRANT USAGE ON SCHEMA vault TO bob WITH GRANT OPTION;
GRANT SELECT ON vault.secrets, vault.decrypted_secrets TO bob WITH GRANT OPTION;
GRANT EXECUTE ON FUNCTION
  vault.create_secret,
  vault.update_secret,
  vault._crypto_aead_det_decrypt
TO bob WITH GRANT OPTION;
