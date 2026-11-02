CREATE TABLE vault.secrets (
  id uuid     PRIMARY KEY DEFAULT gen_random_uuid(),
  name        text,
  description text NOT NULL default '',
  secret      text NOT NULL,
  key_id      uuid,
  nonce       bytea,
  created_at  timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE FUNCTION vault.create_secret(new_secret text
                                  , new_name text = CAST(NULL AS text)
                                  , new_description text = CAST('' AS text)
                                  , new_key_id uuid = CAST(NULL AS uuid))
RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'pg_catalog', 'pg_temp'
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
  SET secret = encode(public.pgp_sym_encrypt(
	rec.secret,
	  vault._get_secret_key()::text
  ), 'base64')
  WHERE id = rec.id;
  RETURN rec.id;
END
$$;

ALTER FUNCTION vault.create_secret (new_secret text, new_name text, new_description text, new_key_id uuid) OWNER TO postgres;

CREATE FUNCTION vault.update_secret(secret_id uuid
                                  , new_secret text = CAST(NULL AS text)
                                  , new_name text = CAST(NULL AS text)
                                  , new_description text = CAST(NULL AS text)
                                  , new_key_id uuid = CAST(NULL AS uuid))
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'pg_catalog', 'pg_temp'
AS $$
BEGIN
  UPDATE vault.secrets s
  SET
    secret = CASE WHEN new_secret IS NULL THEN s.secret
  ELSE encode(public.pgp_sym_encrypt(
	new_secret,
	  vault._get_secret_key()::text
  ), 'base64') END,

                  -- ELSE encode(vault._crypto_aead_det_encrypt(
                  --   message := convert_to(new_secret, 'utf8'),
                  --   additional := convert_to(s.id::text, 'utf8'),
                  --   key_id := 0,
                  --   context := 'pgsodium'::bytea,
                  --   nonce := s.nonce
                  -- ), 'base64') END,
    name = coalesce(new_name, s.name),
    description = coalesce(new_description, s.description),
    updated_at = now()
  WHERE s.id = secret_id;
END
$$;

CREATE OR REPLACE FUNCTION vault._get_secret_key()
RETURNS bytea
AS 'MODULE_PATHNAME', '_get_secret_key'
LANGUAGE c IMMUTABLE;

CREATE VIEW vault.decrypted_secrets AS
SELECT s.id,
  s.name,
  s.description,
  s.secret,
	public.pgp_sym_decrypt(
	  decode(s.secret, 'base64'),
	  vault._get_secret_key()::text
	)
   AS decrypted_secret,
  s.key_id,
  s.nonce,
  s.created_at,
  s.updated_at
FROM vault.secrets s;
ALTER FUNCTION vault.update_secret (secret_id uuid, new_secret text, new_name text, new_description text, new_key_id uuid) OWNER TO postgres;

REVOKE ALL PRIVILEGES
  ON FUNCTION vault._get_secret_key()
  FROM PUBLIC;

REVOKE ALL PRIVILEGES
  ON FUNCTION vault.create_secret (new_secret text, new_name text, new_description text, new_key_id uuid)
  FROM PUBLIC;

REVOKE ALL PRIVILEGES
  ON FUNCTION vault.update_secret (secret_id uuid, new_secret text, new_name text, new_description text, new_key_id uuid)
  FROM PUBLIC;
