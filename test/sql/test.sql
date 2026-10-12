select no_plan();

do $$
begin
  perform vault.create_secret('s3kr3t_k3y', 'a_name', 'this is the foo secret key');
end
$$;

SELECT results_eq(
    $$
    SELECT decrypted_secret = 's3kr3t_k3y', description = 'this is the foo secret key'
    FROM vault.decrypted_secrets WHERE name = 'a_name';
    $$,
    $$VALUES (true, true)$$,
    'can select from masking view with custom key');

SELECT lives_ok(
	$test$
	select vault.update_secret(
	    (select id from vault.secrets where name = 'a_name'), new_name:='a_new_name',
	    new_secret:='new_s3kr3t_k3y', new_description:='this is the bar key')
	$test$,
	'can update name, secret and description'
	);

TRUNCATE vault.secrets;

set role bob;

do $$
begin
  perform vault.create_secret ('foo', 'bar', 'baz');
end
$$;

select results_eq(
	$test$
    SELECT (decrypted_secret COLLATE "default"), name, description FROM vault.decrypted_secrets
    WHERE name = 'bar'
    $test$,
    $results$values ('foo', 'bar', 'baz')$results$,
     'bob can query a secret');

select lives_ok(
	$test$
	select vault.update_secret(
    (select id from vault.secrets where name = 'bar'),
    'fooz',
    'barz',
    'bazz')
	$test$,
     'bob can update a secret');

select results_eq(
    $test$
    SELECT (decrypted_secret COLLATE "default"), name, description
    FROM vault.decrypted_secrets
    $test$,
    $results$values ('fooz', 'barz', 'bazz')$results$,
     'bob can query an updated secret');

reset role;
truncate vault.secrets;

do $$
begin
  perform vault.create_secret(
    new_secret := '',
    new_name := 'empty_secret'
  );
end
$$;

select results_eq(
  $test$
    select decrypted_secret collate "default"
    from vault.decrypted_secrets
    where name = 'empty_secret'
  $test$,
  $results$values ('')$results$,
  'secret can be an empty string'
);

-- PSQLEXT-1780: a caller must not be able to shadow types used by the
-- SECURITY DEFINER functions with objects in their own pg_temp schema
set role bob;

create function pg_temp.vault_pg_temp_check(v pg_catalog.text)
returns pg_catalog.bool
language plpgsql
set search_path = pg_catalog
as $$
begin
  -- only fires if the check runs with the privileges of the function owner
  if current_user <> 'bob' then
    raise exception 'pg_temp domain check executed as %', current_user;
  end if;
  return true;
end
$$;

create domain pg_temp.text as pg_catalog.text
  check (pg_temp.vault_pg_temp_check(value));
create domain pg_temp.bytea as pg_catalog.bytea
  check (pg_temp.vault_pg_temp_check(pg_catalog.encode(value, 'hex')));

select lives_ok(
  $test$
  select vault.create_secret('pg_temp_secret', 'pg_temp_name', 'pg_temp_desc')
  $test$,
  'create_secret does not resolve types from pg_temp');

select lives_ok(
  $test$
  select vault.update_secret(
    (select id from vault.secrets where name = 'pg_temp_name'),
    'pg_temp_secret_2',
    'pg_temp_name_2',
    'pg_temp_desc_2')
  $test$,
  'update_secret does not resolve types from pg_temp');

drop domain pg_temp.text;
drop domain pg_temp.bytea;
drop function pg_temp.vault_pg_temp_check(pg_catalog.text);

select results_eq(
  $test$
    select (decrypted_secret collate "default"), name, description
    from vault.decrypted_secrets
    where name like 'pg_temp_name%'
  $test$,
  $results$values ('pg_temp_secret_2', 'pg_temp_name_2', 'pg_temp_desc_2')$results$,
  'secret created and updated with shadowed pg_temp types');

reset role;

select * from finish();
