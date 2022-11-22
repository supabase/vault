
BEGIN;

CREATE EXTENSION pgtap;
CREATE EXTENSION pgsodium;
CREATE EXTENSION supabase_vault;

select plan(3);

SET ROLE postgres;

SELECT lives_ok(
  format(
    $test$
    INSERT INTO vault.secrets (secret, description) VALUES ('s3kr3t_k3y', 'this is the foo api key');
    $test$),
    'can insert into foo table');

SELECT results_eq(
    $$SELECT decrypted_secret = 's3kr3t_k3y', description = 'this is the foo api key' FROM vault.decrypted_secrets$$,
    $$VALUES (true, true)$$,
    'can select from masking view');

UPDATE vault.secrets SET description = 'bad';

SELECT throws_ok(
  $$SELECT decrypted_secret = 's3kr3t_k3y' FROM vault.decrypted_secrets$$,
  '22000',
  'pgsodium_crypto_aead_det_decrypt_by_id: invalid ciphertext',
  'mutated description data fails decryption');

TRUNCATE vault.secrets;

RESET ROLE;

select * from finish();
ROLLBACK
