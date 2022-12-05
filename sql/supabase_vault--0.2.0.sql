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
        description text NOT NULL default '',
        secret      text NOT NULL,
        key_id      uuid REFERENCES pgsodium.key(id) DEFAULT %L,
        nonce       bytea DEFAULT pgsodium.crypto_aead_det_noncegen(),
        created_at  timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at  timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
      );
      $f$, default_key_id);
  END;
$$;

COMMENT ON TABLE vault.secrets IS 'Table with encrypted `secret` column for storing sensitive information on disk.';

CREATE UNIQUE INDEX ON vault.secrets USING btree (name) WHERE name IS NOT NULL;

SECURITY LABEL FOR pgsodium ON COLUMN vault.secrets.secret IS
'ENCRYPT WITH KEY COLUMN key_id ASSOCIATED (id, description, created_at, updated_at) NONCE nonce';

GRANT ALL ON SCHEMA vault TO pgsodium_keyiduser;
GRANT ALL ON TABLE vault.secrets TO pgsodium_keyiduser;
GRANT ALL PRIVILEGES ON vault.decrypted_secrets TO pgsodium_keyiduser;

CREATE OR REPLACE FUNCTION vault.create_secret(
    new_secret text,
    new_name text = NULL,
    new_description text = '') RETURNS uuid AS
    $$
    INSERT INTO vault.secrets (secret, name, description)
    VALUES (new_secret, new_name, new_description)
    RETURNING id;
    $$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION vault.update_secret(
    secret_id uuid,
    new_secret text = NULL,
    new_name text = NULL,
    new_description text = NULL,
    new_key_id uuid = NULL) RETURNS void AS
    $$
    UPDATE vault.decrypted_secrets ds
    SET
        secret = CASE WHEN new_secret IS NULL THEN ds.decrypted_secret ELSE new_secret END,
        name = CASE WHEN new_name IS NULL THEN ds.name ELSE new_name END,
        description = CASE WHEN new_description IS NULL THEN ds.description ELSE new_description END,
        key_id = CASE WHEN new_key_id IS NULL THEN ds.key_id ELSE new_key_id END,
        updated_at = CURRENT_TIMESTAMP
    FROM  vault.secrets s 
    WHERE ds.id = secret_id AND s.id = ds.id
    $$ LANGUAGE SQL;

SELECT pg_catalog.pg_extension_config_dump('vault.secrets', '');
