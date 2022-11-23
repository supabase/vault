\set ECHO none
\set QUIET 1

\pset format unaligned
\pset tuples_only true
\pset pager

\set ON_ERROR_ROLLBACK 1
\set ON_ERROR_STOP on

BEGIN;

CREATE EXTENSION IF NOT EXISTS pgtap;
CREATE EXTENSION supabase_vault CASCADE;

select plan(3);

CREATE ROLE bob login password 'bob';
GRANT pgsodium_keyiduser TO bob;

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
COMMIT;

\c postgres bob

select plan(2);

select lives_ok($test$
    INSERT INTO vault.secrets (name, description, secret) VALUES ('foo', 'bar', 'baz')$test$,
     'bob can insert a secret');

select results_eq($test$
    SELECT name, description, (decrypted_secret COLLATE "default") FROM vault.decrypted_secrets$test$,
    $results$values ('foo', 'bar', 'baz')$results$,
     'bob can query a secret');

select * from finish();
