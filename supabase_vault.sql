CREATE SCHEMA vault;

ALTER SCHEMA vault OWNER TO postgres;

CREATE FUNCTION vault._crypto_aead_det_decrypt(message bytea
                                             , additional bytea
                                             , key_id bigint
                                             , context bytea = CAST('\x7067736f6469756d' AS bytea)
                                             , nonce bytea = CAST(NULL AS bytea))
RETURNS bytea
LANGUAGE c IMMUTABLE AS '$libdir/supabase_vault'
                      , 'pgsodium_crypto_aead_det_decrypt_by_id';

ALTER FUNCTION vault._crypto_aead_det_decrypt (message bytea, additional bytea, key_id bigint, context bytea, nonce bytea) OWNER TO postgres;

CREATE FUNCTION vault._crypto_aead_det_encrypt(message bytea
                                             , additional bytea
                                             , key_id bigint
                                             , context bytea = CAST('\x7067736f6469756d' AS bytea)
                                             , nonce bytea = CAST(NULL AS bytea))
RETURNS bytea
LANGUAGE c IMMUTABLE AS '$libdir/supabase_vault'
                      , 'pgsodium_crypto_aead_det_encrypt_by_id';

ALTER FUNCTION vault._crypto_aead_det_encrypt (message bytea, additional bytea, key_id bigint, context bytea, nonce bytea) OWNER TO postgres;

CREATE FUNCTION vault._crypto_aead_det_noncegen()
RETURNS bytea
LANGUAGE c IMMUTABLE AS '$libdir/supabase_vault'
                      , 'pgsodium_crypto_aead_det_noncegen';

ALTER FUNCTION vault._crypto_aead_det_noncegen () OWNER TO postgres;

CREATE FUNCTION vault.create_secret(new_secret text
                                  , new_name text = CAST(NULL AS text)
                                  , new_description text = CAST('' AS text)
                                  , new_key_id uuid = CAST(NULL AS uuid))
RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
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

ALTER FUNCTION vault.create_secret (new_secret text, new_name text, new_description text, new_key_id uuid) OWNER TO postgres;

CREATE FUNCTION vault.update_secret(secret_id uuid
                                  , new_secret text = CAST(NULL AS text)
                                  , new_name text = CAST(NULL AS text)
                                  , new_description text = CAST(NULL AS text)
                                  , new_key_id uuid = CAST(NULL AS uuid))
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
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

ALTER FUNCTION vault.update_secret (secret_id uuid, new_secret text, new_name text, new_description text, new_key_id uuid) OWNER TO postgres;

GRANT USAGE
  ON SCHEMA vault
  TO bob
  WITH GRANT OPTION;

REVOKE ALL PRIVILEGES
  ON FUNCTION vault._crypto_aead_det_decrypt (message bytea, additional bytea, key_id bigint, context bytea, nonce bytea)
  FROM PUBLIC;

GRANT ALL PRIVILEGES
  ON FUNCTION vault._crypto_aead_det_decrypt (message bytea, additional bytea, key_id bigint, context bytea, nonce bytea)
  TO bob
  WITH GRANT OPTION;

REVOKE ALL PRIVILEGES
  ON FUNCTION vault._crypto_aead_det_encrypt (message bytea, additional bytea, key_id bigint, context bytea, nonce bytea)
  FROM PUBLIC;

REVOKE ALL PRIVILEGES
  ON FUNCTION vault._crypto_aead_det_noncegen ()
  FROM PUBLIC;

REVOKE ALL PRIVILEGES
  ON FUNCTION vault.create_secret (new_secret text, new_name text, new_description text, new_key_id uuid)
  FROM PUBLIC;

GRANT ALL PRIVILEGES
  ON FUNCTION vault.create_secret (new_secret text, new_name text, new_description text, new_key_id uuid)
  TO bob
  WITH GRANT OPTION;

REVOKE ALL PRIVILEGES
  ON FUNCTION vault.update_secret (secret_id uuid, new_secret text, new_name text, new_description text, new_key_id uuid)
  FROM PUBLIC;

GRANT ALL PRIVILEGES
  ON FUNCTION vault.update_secret (secret_id uuid, new_secret text, new_name text, new_description text, new_key_id uuid)
  TO bob
  WITH GRANT OPTION
