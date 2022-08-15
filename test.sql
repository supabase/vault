
BEGIN;

CREATE EXTENSION pgtap;
CREATE SCHEMA pgsodium;
CREATE EXTENSION pgsodium WITH SCHEMA pgsodium CASCADE;

CREATE EXTENSION supabase_vault CASCADE;

select plan(3);

SET ROLE postgres;

SELECT lives_ok(
  format(
    $test$
    INSERT INTO vault.secrets (secret, associated) VALUES ('s3kr3t_k3y', 'this is the foo api key');
    $test$),
    'can insert into foo table');

SELECT results_eq(
    $$SELECT decrypted_secret = 's3kr3t_k3y', associated = 'this is the foo api key' FROM pgsodium_masks.secrets$$,
    $$VALUES (true, true)$$,
    'can select from masking view');

UPDATE vault.secrets SET associated = 'bad';

SELECT throws_ok(
  $$SELECT decrypted_secret = 's3kr3t_k3y' FROM pgsodium_masks.secrets$$,
  '22000',
  'pgsodium_crypto_aead_det_decrypt_by_id: invalid ciphertext',
  'mutated associated data fails decryption');

TRUNCATE vault.secrets;

RESET ROLE;

select * from finish();
ROLLBACK
