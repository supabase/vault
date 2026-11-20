-- enum containing all valid ciphers
CREATE TYPE vault.ciphers AS ENUM ('x-chacha-20', 'aes-256-gcm');

-- add new ciphers column to track what cipher each secret uses
ALTER TABLE vault.secrets 
ADD COLUMN cipher vault.ciphers;

-- All old secrets us x-chacha-20
UPDATE vault.secrets 
SET cipher = 'x-chacha-20';

-- All new secrets will use aes-256-gcm
ALTER TABLE vault.secrets 
ALTER COLUMN cipher 
SET DEFAULT 'aes-256-gcm';

DROP VIEW vault.decrypted_secrets;
DROP FUNCTION vault._crypto_aead_det_decrypt(bytea, bytea, bigint, bytea, bytea);

CREATE FUNCTION vault._crypto_aead_det_decrypt(message bytea, additional bytea, key_id bigint, context bytea = 'pgsodium', nonce bytea = NULL, cipher vault.ciphers = 'aes-256-gcm')
RETURNS bytea
AS 'MODULE_PATHNAME', 'pgsodium_crypto_aead_det_decrypt_by_id'
LANGUAGE c IMMUTABLE;

REVOKE ALL ON FUNCTION vault._crypto_aead_det_decrypt FROM PUBLIC;

CREATE OR REPLACE VIEW vault.decrypted_secrets AS
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
      nonce := s.nonce,
      cipher := s.cipher
    ),
    'utf8'::name
  ) AS decrypted_secret,
  s.key_id,
  s.nonce,
  s.created_at,
  s.updated_at
FROM vault.secrets s;
