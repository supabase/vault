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

select * from finish();
