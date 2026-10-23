-- Search pg_temp last so callers can't shadow types (e.g. text, bytea) with temp objects that run as the function owner
ALTER FUNCTION vault.create_secret(text, text, text, uuid) SET search_path = pg_catalog, pg_temp;

CREATE OR REPLACE FUNCTION vault.update_secret(
  secret_id uuid,
  new_secret text = NULL,
  new_name text = NULL,
  new_description text = NULL,
  -- unused
  new_key_id uuid = NULL
)
RETURNS void
SECURITY DEFINER
LANGUAGE plpgsql
SET search_path = 'pg_catalog, pg_temp'
AS $$
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
