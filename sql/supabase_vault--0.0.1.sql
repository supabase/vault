SELECT pgsodium.create_key(
  'This is the initial key id used for vault.secrets',
  key_id:=1,
  key_context:='supabase');

GRANT pgsodium_keyiduser TO postgres WITH ADMIN OPTION;
GRANT pgsodium_keyholder TO postgres WITH ADMIN OPTION;
GRANT pgsodium_keymaker  TO postgres WITH ADMIN OPTION;

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
      
      SECURITY LABEL FOR pgsodium ON COLUMN vault.secrets.secret IS
      'ENCRYPT WITH KEY COLUMN key_id ASSOCIATED associated NONCE nonce';
      $f$, default_key_id);
  END;
$$;

ALTER EXTENSION supabase_vault DROP VIEW pgsodium_masks.secrets;  -- let pgsodium own this


