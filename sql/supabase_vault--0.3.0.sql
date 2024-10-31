CREATE OR REPLACE FUNCTION vault._crypto_aead_det_encrypt(message bytea, additional bytea, key_id bigint, context bytea = 'pgsodium', nonce bytea = NULL)
RETURNS bytea
AS 'MODULE_PATHNAME', 'pgsodium_crypto_aead_det_encrypt_by_id'
LANGUAGE c IMMUTABLE;

CREATE OR REPLACE FUNCTION vault._crypto_aead_det_decrypt(message bytea, additional bytea, key_id bigint, context bytea = 'pgsodium', nonce bytea = NULL)
RETURNS bytea
AS 'MODULE_PATHNAME', 'pgsodium_crypto_aead_det_decrypt_by_id'
LANGUAGE c IMMUTABLE;

CREATE OR REPLACE FUNCTION vault._crypto_aead_det_noncegen()
RETURNS bytea
AS 'MODULE_PATHNAME', 'pgsodium_crypto_aead_det_noncegen'
LANGUAGE c IMMUTABLE;

CREATE TABLE vault.secrets (
  id uuid     PRIMARY KEY DEFAULT gen_random_uuid(),
  name        text,
  description text NOT NULL default '',
  secret      text NOT NULL,
  key_id      uuid,
  nonce       bytea DEFAULT vault._crypto_aead_det_noncegen(),
  created_at  timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE vault.secrets IS 'Table with encrypted `secret` column for storing sensitive information on disk.';

CREATE UNIQUE INDEX ON vault.secrets USING btree (name) WHERE name IS NOT NULL;

DROP VIEW IF EXISTS vault.decrypted_secrets;
CREATE VIEW vault.decrypted_secrets AS
SELECT s.id,
  s.name,
  s.description,
  s.secret,
  convert_from(
    vault._crypto_aead_det_decrypt(
      message := decode(s.secret, 'base64'::text),
      additional := convert_to(s.id::text, 'utf8'),
      key_id := 0,
      context := 'pgsodium'::bytea,
      nonce := s.nonce
    ),
    'utf8'::name
  ) AS decrypted_secret,
  s.key_id,
  s.nonce,
  s.created_at,
  s.updated_at
FROM vault.secrets s;

GRANT ALL ON SCHEMA vault TO pgsodium_keyiduser;
GRANT ALL ON TABLE vault.secrets TO pgsodium_keyiduser;
GRANT ALL ON vault.decrypted_secrets TO pgsodium_keyiduser;

CREATE OR REPLACE FUNCTION vault.create_secret(
  new_secret text,
  new_name text = NULL,
  new_description text = '',
  -- unused
  new_key_id uuid = NULL
)
RETURNS uuid
LANGUAGE plpgsql
SET search_path = ''
AS $$
DECLARE
  rec record;
BEGIN
  INSERT INTO vault.secrets (secret, name, description)
  VALUES (
    new_secret,
    new_name,
    new_description
  )
  RETURNING * INTO rec;
  UPDATE vault.secrets s
  SET secret = encode(vault._crypto_aead_det_encrypt(
    message := convert_to(rec.secret, 'utf8'),
    additional := convert_to(s.id::text, 'utf8'),
    key_id := 0,
    context := 'pgsodium'::bytea,
    nonce := rec.nonce
  ), 'base64')
  WHERE id = rec.id;
  RETURN rec.id;
END
$$;

CREATE OR REPLACE FUNCTION vault.update_secret(
  secret_id uuid,
  new_secret text = NULL,
  new_name text = NULL,
  new_description text = NULL,
  -- unused
  new_key_id uuid = NULL
)
RETURNS void
LANGUAGE plpgsql
SET search_path = ''
AS $$
DECLARE
  decrypted_secret text := (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE id = secret_id);
BEGIN
  UPDATE vault.secrets s
  SET
    secret = CASE WHEN new_secret IS NULL THEN s.secret
                  ELSE encode(vault._crypto_aead_det_encrypt(
                    message := convert_to(new_secret, 'utf8'),
                    additional := convert_to(s.id::text, 'utf8'),
                    key_id := 0,
                    context := 'pgsodium'::bytea,
                    nonce := s.nonce
                  ), 'base64') END,
    name = coalesce(new_name, s.name),
    description = coalesce(new_description, s.description),
    updated_at = now()
  WHERE s.id = secret_id;
END
$$;

SELECT pg_catalog.pg_extension_config_dump('vault.secrets', '');
