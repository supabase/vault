CREATE OR REPLACE FUNCTION vault.create_secret(new_secret text
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
  SET secret = pg_catalog.encode(vault._crypto_aead_det_encrypt(
    message := pg_catalog.convert_to(rec.secret, 'utf8'),
    additional := pg_catalog.convert_to(s.id::pg_catalog.text, 'utf8'),
    key_id := 0,
    context := 'pgsodium'::pg_catalog.bytea,
    nonce := rec.nonce
  ), 'base64')
  WHERE s.id OPERATOR(pg_catalog.=) rec.id;
  RETURN rec.id;
END
$$;


CREATE OR REPLACE FUNCTION vault.update_secret(secret_id uuid
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
                  ELSE pg_catalog.encode(vault._crypto_aead_det_encrypt(
                    message := pg_catalog.convert_to(new_secret, 'utf8'),
                    additional := pg_catalog.convert_to(s.id::pg_catalog.text, 'utf8'),
                    key_id := 0,
                    context := 'pgsodium'::pg_catalog.bytea,
                    nonce := s.nonce
                  ), 'base64') END,
    name = coalesce(new_name, s.name),
    description = coalesce(new_description, s.description),
    updated_at = pg_catalog.now()
  WHERE s.id OPERATOR(pg_catalog.=) secret_id;
END
$$;
