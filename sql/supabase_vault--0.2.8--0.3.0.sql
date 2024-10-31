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

SECURITY LABEL ON COLUMN vault.secrets.secret IS NULL;

DROP TRIGGER IF EXISTS secrets_encrypt_secret_trigger_secret ON vault.secrets;
DROP FUNCTION IF EXISTS vault.secrets_encrypt_secret_secret;

ALTER TABLE vault.secrets DROP CONSTRAINT IF EXISTS secrets_key_id_fkey;
ALTER TABLE vault.secrets ALTER key_id DROP DEFAULT;
ALTER TABLE vault.secrets ALTER nonce SET DEFAULT vault._crypto_aead_det_noncegen();

DO $$
BEGIN
  SET search_path = '';

  IF EXISTS (SELECT FROM vault.secrets) THEN
    UPDATE vault.decrypted_secrets s
    SET
      secret = encode(
        vault._crypto_aead_det_encrypt(
          message := convert_to(decrypted_secret, 'utf8'),
          additional := convert_to(s.id::text, 'utf8'),
          key_id := 0,
          context := 'pgsodium'::bytea,
          nonce := s.nonce
        ),
        'base64'
      ),
      key_id = NULL;
  END IF;
END
$$;

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
