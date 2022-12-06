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

select plan(4);

CREATE ROLE bob login password 'bob';
GRANT pgsodium_keyiduser TO bob;

select vault.create_secret ('s3kr3t_k3y', 'a_name', 'this is the foo key') test_secret_id \gset

select vault.create_secret (
	's3kr3t_k3y_2', 'another_name', 'this is another foo key',
	(select id from pgsodium.key where name = 'default_vault_key')) test_secret_id \gset

SELECT results_eq(
    $$
    SELECT decrypted_secret = 's3kr3t_k3y', description = 'this is the foo key'
    FROM vault.decrypted_secrets WHERE name = 'a_name';
    $$,
    $$VALUES (true, true)$$,
    'can select from masking view with custome key');

SELECT results_eq(
    $$
    SELECT decrypted_secret = 's3kr3t_k3y_2', description = 'this is another foo key'
    FROM vault.decrypted_secrets WHERE key_id = (select id from pgsodium.key where name = 'default_vault_key');
    $$,
    $$VALUES (true, true)$$,
    'can select from masking view');

select vault.update_secret(
    :'test_secret_id',
    new_description:='this is the bar key');

SELECT results_eq(
    $$
    UPDATE vault.decrypted_secrets
    SET description = 'this is the bar key', secret = decrypted_secret
    where name = 'a_name' returning name, decrypted_secret collate "default", description;
    $$,
    $$values('a_name','s3kr3t_k3y','this is the bar key')$$,
    'can update description');

TRUNCATE vault.secrets;
COMMIT;

\c postgres bob

select plan(3);

select vault.create_secret ('foo', 'bar', 'baz') bob_secret_id \gset

select results_eq(
    format(
	$test$
    SELECT (decrypted_secret COLLATE "default"), name, description FROM vault.decrypted_secrets
    WHERE id = %L::uuid
    $test$,
	:'bob_secret_id'),
    $results$values ('foo', 'bar', 'baz')$results$,
     'bob can query a secret');

select vault.update_secret(
    :'bob_secret_id',
    'fooz',
    'barz',
    'bazz');

select results_eq(
    $test$
    SELECT (decrypted_secret COLLATE "default"), name, description
    FROM vault.decrypted_secrets
    $test$,
    $results$values ('fooz', 'barz', 'bazz')$results$,
     'bob can query an updated secret');

select vault.update_secret(:'bob_secret_id', new_key_id:=(pgsodium.create_key()).id);

select results_eq(
    format(
	$test$
    SELECT (decrypted_secret COLLATE "default"), name, description
    FROM vault.decrypted_secrets
    WHERE id = %L::uuid;
    $test$,
	:'bob_secret_id'),
    $results$values ('fooz', 'barz', 'bazz')$results$,
     'bob can rotate a key id');

select * from finish();
