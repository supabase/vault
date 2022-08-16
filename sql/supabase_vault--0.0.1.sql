CREATE SCHEMA IF NOT EXISTS vault;

SELECT pgsodium.create_key(
  'This is the initial key id used for vault.secrets',
  key_id:=1,
  key_context:='supabase');

DO $$
  DECLARE
  default_key_id uuid;
  BEGIN
    SELECT id INTO STRICT default_key_id FROM pgsodium.key WHERE key_id = 1 AND key_context = 'supabase';
    EXECUTE format(
      $f$
      CREATE TABLE vault.secrets (
        id uuid    PRIMARY KEY DEFAULT gen_random_uuid(),
        secret     text,
        key_id     uuid REFERENCES pgsodium.key(id) DEFAULT %L,
        associated text DEFAULT '',
        nonce      bytea DEFAULT pgsodium.crypto_aead_det_noncegen(),
        created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
      );
      $f$, default_key_id);
  END;
$$;

GRANT ALL ON SCHEMA vault TO postgres;
GRANT ALL ON TABLE vault.secrets TO postgres;

SECURITY LABEL FOR pgsodium ON COLUMN vault.secrets.secret IS
'ENCRYPT WITH KEY COLUMN key_id ASSOCIATED associated NONCE nonce';

SELECT pg_catalog.pg_extension_config_dump('vault.secrets', '');

ALTER EXTENSION supabase_vault DROP VIEW pgsodium_masks.secrets;  -- so the view can be recreated
