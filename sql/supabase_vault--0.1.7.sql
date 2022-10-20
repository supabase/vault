SELECT pgsodium.create_key(
        name := 'default_vault_key'
        );

ALTER EVENT TRIGGER pgsodium_trg_mask_update DISABLE;

DO $$
  DECLARE
  default_key_id uuid;
  BEGIN
    SELECT id INTO STRICT default_key_id FROM pgsodium.key WHERE name = 'default_vault_key';
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

COMMENT ON TABLE vault.secrets IS 'Table with encrypted `secret` column for storing sensitive information on disk.';

GRANT ALL ON SCHEMA vault TO postgres;
GRANT ALL ON TABLE vault.secrets TO postgres;

-- Have to disable system wide event trigger so only this one view
-- gets generated and "owned" by the extension.

SECURITY LABEL FOR pgsodium ON COLUMN vault.secrets.secret IS
'ENCRYPT WITH KEY COLUMN key_id ASSOCIATED associated NONCE nonce';

-- FIXME add a utility function that does this
SELECT pgsodium.create_mask_view(objoid, objsubid, false)
    FROM pg_seclabel
    WHERE objoid = 'vault.secrets'::regclass::oid
        AND label ILIKE 'ENCRYPT%'
        AND provider = 'pgsodium';

ALTER EVENT TRIGGER pgsodium_trg_mask_update ENABLE;

SELECT pg_catalog.pg_extension_config_dump('vault.secrets', '');
