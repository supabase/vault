SELECT pgsodium.create_key(
        name := 'default_vault_key'
        );

DO $$
  DECLARE
  default_key_id uuid;
  BEGIN
    SELECT id INTO STRICT default_key_id FROM pgsodium.key WHERE name = 'default_vault_key';
    EXECUTE format(
      $f$
      CREATE TABLE vault.secrets (
        id uuid     PRIMARY KEY DEFAULT gen_random_uuid(),
        name        text,
        description text,
        secret      text,
        key_id      uuid REFERENCES pgsodium.key(id) DEFAULT %L,
        nonce       bytea DEFAULT pgsodium.crypto_aead_det_noncegen(),
        created_at  timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
      );
      $f$, default_key_id);
  END;
$$;

COMMENT ON TABLE vault.secrets IS 'Table with encrypted `secret` column for storing sensitive information on disk.';

CREATE UNIQUE INDEX ON vault.secrets USING btree (name) WHERE name IS NOT NULL;

GRANT ALL ON SCHEMA vault TO postgres;
GRANT ALL ON TABLE vault.secrets TO postgres;

SECURITY LABEL FOR pgsodium ON COLUMN vault.secrets.secret IS
'ENCRYPT WITH KEY COLUMN key_id ASSOCIATED (id, name, description, created_at) NONCE nonce';

-- ALTER EXTENSION supabase_vault DROP VIEW vault.decrypted_secrets;
-- ALTER EXTENSION supabase_vault DROP FUNCTION vault.secrets_encrypt_secret;

SELECT pg_catalog.pg_extension_config_dump('vault.secrets', '');
