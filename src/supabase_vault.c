#include <postgres.h>

#include <sodium.h>
#include <utils/builtins.h>
#include <utils/guc.h>
#include <miscadmin.h>
#include <unistd.h>
#include <storage/ipc.h>

#include "pgsodium.h"

PG_MODULE_MAGIC;

void _PG_init(void);

void
_PG_init (void)
{
	FILE       *fp;
	char       *secret_buf = NULL;
	size_t      secret_len = 0;
	size_t      char_read;
	char       *path;
	char        sharepath[MAXPGPATH];

	if (sodium_init () == -1)
	{
		elog (ERROR,
			"_PG_init: sodium_init() failed cannot initialize supabase_vault");
		return;
	}

	// we're done if not preloaded, otherwise try to get internal shared key
	if (!process_shared_preload_libraries_in_progress)
		return;

	path = (char *) palloc0 (MAXPGPATH);
	get_share_path (my_exec_path, sharepath);
	snprintf (path, MAXPGPATH, "%s/extension/%s", sharepath, PG_GETKEY_EXEC);

	DefineCustomStringVariable ("vault.getkey_script",
		"path to script that returns vault root key",
		NULL, &getkey_script, path, PGC_POSTMASTER, 0, NULL, NULL, NULL);

	if (access (getkey_script, X_OK) == -1)
	{
		if (errno == ENOENT)
			ereport(ERROR, (
				errmsg("The getkey script \"%s\" does not exist.", getkey_script),
				errdetail("The getkey script fetches the primary server secret key."),
				errhint("You might want to create it and/or set \"vault.getkey_script\" to the correct path.")));
		else if (errno == EACCES)
			ereport(ERROR,
				errmsg("Permission denied for the getkey script \"%s\"",
					getkey_script));
		else
			ereport(ERROR,
				errmsg("Can not access getkey script \"%s\"", getkey_script));
		proc_exit (1);
	}

	if ((fp = popen (getkey_script, "r")) == NULL)
	{
		ereport(ERROR,
			errmsg("%s: could not launch shell command from", getkey_script));
		proc_exit (1);
	}

	char_read = getline (&secret_buf, &secret_len, fp);
	if (secret_buf[char_read - 1] == '\n')
		secret_buf[char_read - 1] = '\0';

	secret_len = strlen (secret_buf);

	if (secret_len != 64)
	{
		ereport(ERROR, errmsg("invalid secret key"));
		proc_exit (1);
	}

	if (pclose (fp) != 0)
	{
		ereport(ERROR, errmsg( "%s: could not close shell command\n",
			PG_GETKEY_EXEC));
		proc_exit (1);
	}
	pgsodium_secret_key =
		sodium_malloc (crypto_sign_SECRETKEYBYTES + VARHDRSZ);

	if (pgsodium_secret_key == NULL)
	{
		ereport(ERROR, errmsg( "%s: sodium_malloc() failed\n", PG_GETKEY_EXEC));
		proc_exit (1);
	}

	hex_decode (secret_buf, secret_len, VARDATA (pgsodium_secret_key));
	sodium_memzero (secret_buf, secret_len);
	free (secret_buf);
	elog (LOG, "vault primary server secret key loaded");
}
