# Supabase Vault (Beta)

A PostgreSQL extension for managing secrets and sensitive data.

## Introduction

Many applications have sensitive data that must have additional
storage protection relative to other data.  For example, your
application may access external services with an "API Key".  This key
is issued to you by that specific external service provider, and you
must keep it safe from being stolen or leaked.  If someone got their
hands on your payment processor key, for example, they may be able to
use it to send money or digital assets out of your account to someone
else.  Wherever this key is stored, it would make sense to store it in
an encrypted form.

Supabase provides a table called `vault.secrets` that can be used to
store sensitive information like API keys.  These secrets will be
stored in an encrypted format on disk and in any database dumps.
Decrypting this table is done through a special "view" object called
`pgsodium_masks.secrets` that uses an encryption key that is itself
not avaiable to SQL, but can be referred to by ID.  Supabase manages
these internal keys for you, so you can't leak them out of the
database, you can only refer to them by their ids.

## Installation

The Vault extension can be install from the "Extensions" tab on the
dashboard.  Or from SQL you can do:

```sql
CREATE SCHEMA vault;
CREATE EXTENSION supabase_vault WITH SCHEMA vault;
```

The `supabase_vault` extension must go into a schema named `vault`.
This is to avoid any name confusion when accessing the sensitive
`vault.secrets` table.  In general it is always best to refer to it
directly with the full qualified name `vault.secrets`.

## Using the Vault

Using the vault is as simple as `INSERT`ing data into the
`vault.secret` table.

```sql
INSERT INTO vault.secrets (secret) 
VALUES ('s3kr3t_k3y') RETURNING *;
```

```
-[ RECORD 1 ]--------------------------------------------------------
id         | 05fabec2-872b-45e7-abfc-26957afe5b67
secret     | A7GvMKLbwUfIX29R0IDQd3jny+EeG7cVsTvO9Sdw+DfBW7yx37EucHtc
key_id     | 2fb07feb-30fa-42fa-9f5f-df87931629c5
associated |
nonce      | \x9dd8be2eeaa8cee1316cf9f4859daced
created_at | 2022-08-16 21:27:16.555253+00
```

Notice that the 'secret' column is now encrypted with the key id in
the `key_id` column.

You can also insert a text column called "associated".  This data will
be mixed in with the cryptographic signature verification, meaning
that if it changes, the decryption will fail.  This pattern is called
[Authenticated Encryption with Assocaited Data (AEAD)].

```sql
INSERT INTO vault.secrets (secret, associated) 
VALUES ('s3kr3t_k3y', 'This is the payment processor key') 
RETURNING *;
```

```
-[ RECORD 1 ]--------------------------------------------------------
id         | d02f9734-db02-48cd-9fcb-daab9dd34d10
secret     | Czs1s9UxMWkvAsUOlGCdeho37oM8MeCam1kFkwrSBsh/pKydlaPlP/AR
key_id     | 2fb07feb-30fa-42fa-9f5f-df87931629c5
associated | This is the payment processor key
nonce      | \x2fc36f6b6cb3d2dd4aac8d89c65b04d9
created_at | 2022-08-16 21:28:38.980329+00
```

## Querying Data from the Vault

If you look in the `vault.secrets` table, you will see that your data
is stored encrypted:

```sql
select * from vault.secrets;
```

```
-[ RECORD 1 ]--------------------------------------------------------
id         | 05fabec2-872b-45e7-abfc-26957afe5b67
secret     | A7GvMKLbwUfIX29R0IDQd3jny+EeG7cVsTvO9Sdw+DfBW7yx37EucHtc
key_id     | 2fb07feb-30fa-42fa-9f5f-df87931629c5
associated |
nonce      | \x9dd8be2eeaa8cee1316cf9f4859daced
created_at | 2022-08-16 21:27:16.555253+00
-[ RECORD 2 ]--------------------------------------------------------
id         | d02f9734-db02-48cd-9fcb-daab9dd34d10
secret     | Czs1s9UxMWkvAsUOlGCdeho37oM8MeCam1kFkwrSBsh/pKydlaPlP/AR
key_id     | 2fb07feb-30fa-42fa-9f5f-df87931629c5
associated | This is the payment processor key
nonce      | \x2fc36f6b6cb3d2dd4aac8d89c65b04d9
created_at | 2022-08-16 21:28:38.980329+00
```

To decrypt the data, there is an automatically created view
`pgsodium_masks.secrets`.  This view will decrypt secret data on the
fly:

```sql
select * from pgsodium_masks.secrets;
```

```
-[ RECORD 1 ]----+---------------------------------------------------------
id               | 05fabec2-872b-45e7-abfc-26957afe5b67
secret           | A7GvMKLbwUfIX29R0IDQd3jny+EeG7cVsTvO9Sdw+DfBW7yx37EucHtc
decrypted_secret | s3kr3t_k3y
key_id           | 2fb07feb-30fa-42fa-9f5f-df87931629c5
associated       |
nonce            | \x9dd8be2eeaa8cee1316cf9f4859daced
created_at       | 2022-08-16 21:27:16.555253+00
-[ RECORD 2 ]----+---------------------------------------------------------
id               | d02f9734-db02-48cd-9fcb-daab9dd34d10
secret           | Czs1s9UxMWkvAsUOlGCdeho37oM8MeCam1kFkwrSBsh/pKydlaPlP/AR
decrypted_secret | s3kr3t_k3y
key_id           | 2fb07feb-30fa-42fa-9f5f-df87931629c5
associated       | This is the payment processor key
nonce            | \x2fc36f6b6cb3d2dd4aac8d89c65b04d9
created_at       | 2022-08-16 21:28:38.980329+00
```

Notice how this view has a `decrypted_secret` column that contains the
decrypted secret keys.

You should ensure that you protect access to this view with the
appropriate SQL privilege settings at all times, as anyone that has
access to the view has access to decrypted secrets.

## Labeling Users

Automating the process of securing the secrets table for a specific
role can be done with the `SECURITY LABEL` command:

```sql
CREATE ROLE bob WITH LOGIN PASSWORD 'foo';
SECURITY LABEL FOR pgsodium ON ROLE bob IS 'ACCESS vault.secrets';
```

Now when you connect as the role `bob`, the role's search path has
been changed to put the view object in front of the table object in
the search path.  This automatically gives bob access to the view:

```sql
# bob=> 
select * from secrets;
```
```
-[ RECORD 1 ]----+---------------------------------------------------------
id               | 05fabec2-872b-45e7-abfc-26957afe5b67
secret           | A7GvMKLbwUfIX29R0IDQd3jny+EeG7cVsTvO9Sdw+DfBW7yx37EucHtc
decrypted_secret | s3kr3t_k3y
key_id           | 2fb07feb-30fa-42fa-9f5f-df87931629c5
associated       |
nonce            | \x9dd8be2eeaa8cee1316cf9f4859daced
created_at       | 2022-08-16 21:27:16.555253+00
-[ RECORD 2 ]----+---------------------------------------------------------
id               | d02f9734-db02-48cd-9fcb-daab9dd34d10
secret           | Czs1s9UxMWkvAsUOlGCdeho37oM8MeCam1kFkwrSBsh/pKydlaPlP/AR
decrypted_secret | s3kr3t_k3y
key_id           | 2fb07feb-30fa-42fa-9f5f-df87931629c5
associated       | This is the payment processor key
nonce            | \x2fc36f6b6cb3d2dd4aac8d89c65b04d9
created_at       | 2022-08-16 21:28:38.980329+00
```

Labeled roles are granted access to the fully qualified table names
specified in their security label.  This labeling will automatically
grant access to the right view and deny access to the table.  The role
also as their `search_path` login configuration setting altered to the
following:

```sql
# bob=> 
show search_path ;
```
```
-[ RECORD 1 ]---------------------------------------------------
search_path | pgsodium_masks, vault, pg_catalog, public, pg_temp
```

## Internal Details

To encrypt data, you need a *key id*.  You can use the default key id
created automatically for every project, or create your own key ids
Using the `pgsodium.create_key()` function.  Key ids are used to
internally derive the encryption key used to encrypt secrets in the
vault.  Vault users typically do not have access to the key itself,
only the key id.

Which roles should have access to the `vault.secrets` table should be
carefully considered.  There are two ways to grant access, the first
is that the `postgres` user can explicitly grant access to the vault
table itself.

Not entirely clear here on how the grants are going to work without a
working image to test against.

## Turning off Statement Logging

When you insert secrets into the vault table with an INSERT statement,
those statements get logged by default into the Supabase logs.  Since
this would mean your secrets are stored unencrypted in the logs, you
should turn off statement logging while using the Vault.

While turning off statement logging does hinder you if you're used to
looking at the logs to debug your application, it provides a much
higher level of security by ensuring that your data does not leak out
of the database and into the logs.  This is especially critical with
encrypted column data, because the statement logs will contain the
*unencrypted* secrets.  If you *must* store that data encrypted, then
you *must* turn off statement logging.

```sql
ALTER SYSTEM SET statement_log = 'none';
```

And then restart your project from the dashboard to enable that
change.

In the future we are researching various ways to refine the way
statement logging interacts with sensitive columns.
