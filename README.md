# Supabase Vault (BETA)

---
id: vault
title: Encrypted Vault Storage
description: Encrypting Secrets in the Vault table.
---

import Tabs from '@theme/Tabs'
import TabItem from '@theme/TabItem'

## Introduction to the Vault (Beta)

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

```
CREATE SCHEMA vault;
CREATE EXTENSION supabase_vault WITH SCHEMA vault;
```

The `supabase_vault` extension must go into a schema named Vault.
This is to avoid any name confusion when accessing the sensitive
`vault.secrets` table.  In general it is always best to refer to it
directly with the full qualified name `vault.secrets`.

## Using the Vault

Using the vault is as simple as `INSERT`ing data into the
`vault.secret` table.

```
```

You can also insert a text column called "associated".  This data will
be mixed in with the cryptographic signature verification, meaning
that if it changes, the decryption will fail.  This pattern is called
[Authenticated Encryption with Assocaited Data (AEAD)].

```
```

## Querying Data from the Vault

If you look in the `vault.secrets` table, you will see that your data
is stored encrypted.  To decrypt the data, there is an automatically
created view `pgsodium_masks.secrets`.  This view will decrypt secret
data on the fly:

```
```

You should ensure that you protect access to this view with the
appropriate SQL privilege settings at all times, as anyone that has
access to the view has access to decrypted secrets.

## Labeling Users

Automating the process of securing the secrets table for a specific
role can be done with the `SECURITY LABEL` command:

```
select pgsodium.update_masks();
```

Labeled roles are granted access to the fully qualified table names
specified in their security label.  This labeling will automatically
grant access to the right view and deny access to the table.  The role
also as their `search_path` login configuration setting altered to the
following:

```
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

```
ALTER SYSTEM SET statement_log = 'none';
```

And then restart your project from the dashboard to enable that
change.

In the future we are researching various ways to refine the way
statement logging interacts with sensitive columns.


