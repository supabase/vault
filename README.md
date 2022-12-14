# Introduction to the Vault (Beta)

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
stored in an encrypted format on disk and in any database dumps.  This
is often called [Encryption At
Rest](https://en.wikipedia.org/wiki/Data_at_rest).  Decrypting this
table is done through a special database view called
`vault.decrypted_secrets` that uses an encryption key that is itself
not avaiable to SQL, but can be referred to by ID.  Supabase manages
these internal keys for you, so you can't leak them out of the
database, you can only refer to them by their ids.

## Installation

The Vault extension is enabled by default. If you install the Vault 
yourself locally, from SQL you can do:

```
CREATE EXTENSION supabase_vault CASCADE;
```

## Using the Vault

Using the vault is as simple as `INSERT`ing data into the
`vault.secret` table.

```
postgres=> INSERT INTO vault.secrets (secret) VALUES ('s3kre3t_k3y') RETURNING *;
-[ RECORD 1 ]-------------------------------------------------------------
id          | d91596b8-1047-446c-b9c0-66d98af6d001
name        | 
description | 
secret      | S02eXS9BBY+kE3r621IS8beAytEEtj+dDHjs9/0AoMy7HTbog+ylxcS22A==
key_id      | 7f5ad44b-6bd5-4c99-9f68-4b6c7486f927
nonce       | \x3aa2e92f9808e496aa4163a59304b895
created_at  | 2022-12-14 02:29:21.3625+00
updated_at  | 2022-12-14 02:29:21.3625+00
```

There is also a handy function for creating secrets called
`vault.create_secret()`:

```
postgres=> select vault.create_secret('another_s3kre3t');
-[ RECORD 1 ]-+-------------------------------------
create_secret | c9b00867-ca8b-44fc-a81d-d20b8169be17

```

The function returns the UUID of the new secret.

## Name and Description

Secrets can also have an optional _unique_ name, or an optional
description.  These are also arguments to `vault.create_secret()`:

```
postgres=> select vault.create_secret('another_s3kre3t', 'unique_name', 'This is the description');
-[ RECORD 1 ]-+-------------------------------------
create_secret | 7095d222-efe5-4cd5-b5c6-5755b451e223

postgres=> select * from vault.secrets where id = '7095d222-efe5-4cd5-b5c6-5755b451e223';
-[ RECORD 1 ]-----------------------------------------------------------------
id          | 7095d222-efe5-4cd5-b5c6-5755b451e223
name        | unique_name
description | This is the description
secret      | 3mMeOcoG84a5F2uOfy2ugWYDp9sdxvCTmi6kTeT97bvA8rCEsG5DWWZtTU8VVeE=
key_id      | c62da7a0-b85d-471d-8ea7-52aae21d7354
nonce       | \x9f2d60954ba5eb566445736e0760b0e3
created_at  | 2022-12-14 02:34:23.85159+00
updated_at  | 2022-12-14 02:34:23.85159+00
```

## Querying Data from the Vault

If you look in the `vault.secrets` table, you will see that your data
is stored encrypted. To decrypt the data, there is an automatically
created view `vault.decrypted_secrets`.  This view will decrypt secret
data on the fly:

```
postgres=> select * from vault.decrypted_secrets order by created_at desc limit 3;
-[ RECORD 1 ]----+-----------------------------------------------------------------
id               | 7095d222-efe5-4cd5-b5c6-5755b451e223
name             | unique_name
description      | This is the description
secret           | 3mMeOcoG84a5F2uOfy2ugWYDp9sdxvCTmi6kTeT97bvA8rCEsG5DWWZtTU8VVeE=
decrypted_secret | another_s3kre3t
key_id           | c62da7a0-b85d-471d-8ea7-52aae21d7354
nonce            | \x9f2d60954ba5eb566445736e0760b0e3
created_at       | 2022-12-14 02:34:23.85159+00
updated_at       | 2022-12-14 02:34:23.85159+00
-[ RECORD 2 ]----+-----------------------------------------------------------------
id               | c9b00867-ca8b-44fc-a81d-d20b8169be17
name             | 
description      | 
secret           | a1CE4vXwQ53+N9bllJj1D7fasm59ykohjb7K90PPsRFUd9IbBdxIGZNoSQLIXl4=
decrypted_secret | another_s3kre3t
key_id           | 8c72b05e-b931-4372-abf9-a09cfad18489
nonce            | \x1d3b2761548c4efb2d29ca11d44aa22f
created_at       | 2022-12-14 02:32:50.58921+00
updated_at       | 2022-12-14 02:32:50.58921+00
-[ RECORD 3 ]----+-----------------------------------------------------------------
id               | d91596b8-1047-446c-b9c0-66d98af6d001
name             | 
description      | 
secret           | S02eXS9BBY+kE3r621IS8beAytEEtj+dDHjs9/0AoMy7HTbog+ylxcS22A==
decrypted_secret | s3kre3t_k3y
key_id           | 7f5ad44b-6bd5-4c99-9f68-4b6c7486f927
nonce            | \x3aa2e92f9808e496aa4163a59304b895
created_at       | 2022-12-14 02:29:21.3625+00
updated_at       | 2022-12-14 02:29:21.3625+00
```

Notice how this view has a `decrypted_secret` column that contains the
decrypted secrets.  Views are not stored on disk, they are only run at
query time, so the secret remains encrypted on disk, and in any backup
dumps or replication streams.

You should ensure that you protect access to this view with the
appropriate SQL privilege settings at all times, as anyone that has
access to the view has access to decrypted secrets.

## Updating Secrets

A secret can be updated with the `vault.update_secret()` function,
this function makes updating secrets easy, just provide the secret
UUID as the first argument, and then an updated secret, updated
optional unique name, or updated description:

```
postgres=> select vault.update_secret('7095d222-efe5-4cd5-b5c6-5755b451e223', 'n3w_upd@ted_s3kret', 
    'updated_unique_name', 'This is the updated description');
-[ RECORD 1 ]-+-
update_secret | 

postgres=> select * from vault.decrypted_secrets where id = '7095d222-efe5-4cd5-b5c6-5755b451e223';
-[ RECORD 1 ]----+---------------------------------------------------------------------
id               | 7095d222-efe5-4cd5-b5c6-5755b451e223
name             | updated_unique_name
description      | This is the updated description
secret           | lhb3HBFxF+qJzp/HHCwhjl4QFb5dYDsIQEm35DaZQOovdkgp2iy6UMufTKJGH4ThMrU=
decrypted_secret | n3w_upd@ted_s3kret
key_id           | c62da7a0-b85d-471d-8ea7-52aae21d7354
nonce            | \x9f2d60954ba5eb566445736e0760b0e3
created_at       | 2022-12-14 02:34:23.85159+00
updated_at       | 2022-12-14 02:51:13.938396+00
```

## Internal Details

To encrypt data, you need a *key id*.  You can use the default key id
created automatically for every project, or create your own key ids
Using the `pgsodium.create_key()` function.  Key ids are used to
internally derive the encryption key used to encrypt secrets in the
vault.  Vault users typically do not have access to the key itself,
only the key id.

Both `vault.create_secret()` and `vault.update_secret()` take an
optional fourth `new_key_id` argument.  This argument can be used to
store a different key id for the secret instead of the default value.

```
postgres=> select vault.create_secret('another_s3kre3t_key', 'another_unique_name', 
   'This is another description', (pgsodium.create_key()).id);
-[ RECORD 1 ]-+-------------------------------------
create_secret | cec9e005-a44d-4b19-86e1-febf3cd40619
```

Which roles should have access to the `vault.secrets` table should be
carefully considered.  There are two ways to grant access, the first
is that the `postgres` user can explicitly grant access to the vault
table itself.

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

```
ALTER SYSTEM SET statement_log = 'none';
```

And then restart your project from the dashboard to enable that
change.

In the future we are researching various ways to refine the way
statement logging interacts with sensitive columns.
