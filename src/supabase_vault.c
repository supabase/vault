#include <postgres.h>

#include <miscadmin.h>
#include <storage/ipc.h>
#include <unistd.h>
#include <utils/builtins.h>
#include <utils/guc.h>

PG_MODULE_MAGIC;
char *getkey_script = NULL;
bytea *secret_key = NULL;
#define PG_GETKEY_EXEC "getkey"


void _PG_init(void);

void _PG_init(void) {
  FILE *fp;
  char *secret_buf = NULL;
  size_t secret_len = 0;
  size_t char_read;
  char *path;
  char sharepath[MAXPGPATH];


  // we're done if not preloaded, otherwise try to get internal shared key
  if (!process_shared_preload_libraries_in_progress)
    return;

  path = (char *)palloc0(MAXPGPATH);
  get_share_path(my_exec_path, sharepath);
  snprintf(path, MAXPGPATH, "%s/extension/%s", sharepath, PG_GETKEY_EXEC);

  DefineCustomStringVariable(
      "vault.getkey_script", "path to script that returns vault root key", NULL,
      &getkey_script, path, PGC_POSTMASTER, 0, NULL, NULL, NULL);

  if (access(getkey_script, X_OK) == -1) {
    if (errno == ENOENT)
      ereport(
          ERROR,
          (errmsg("The getkey script \"%s\" does not exist.", getkey_script),
           errdetail(
               "The getkey script fetches the primary server secret key."),
           errhint("You might want to create it and/or set "
                   "\"vault.getkey_script\" to the correct path.")));
    else if (errno == EACCES)
      ereport(ERROR, errmsg("Permission denied for the getkey script \"%s\"",
                            getkey_script));
    else
      ereport(ERROR,
              errmsg("Can not access getkey script \"%s\"", getkey_script));
    proc_exit(1);
  }

  if ((fp = popen(getkey_script, "r")) == NULL) {
    ereport(ERROR,
            errmsg("%s: could not launch shell command from", getkey_script));
    proc_exit(1);
  }

  char_read = getline(&secret_buf, &secret_len, fp);
  if (secret_buf[char_read - 1] == '\n')
    secret_buf[char_read - 1] = '\0';

  secret_len = strlen(secret_buf);

  if (secret_len != 64) {
    ereport(ERROR, errmsg("invalid secret key"));
    proc_exit(1);
  }

  if (pclose(fp) != 0) {
    ereport(ERROR,
            errmsg("%s: could not close shell command\n", PG_GETKEY_EXEC));
    proc_exit(1);
  }
  secret_key = malloc(32 + VARHDRSZ);

  if (secret_key == NULL) {
    ereport(ERROR, errmsg("%s: palloc() failed\n", PG_GETKEY_EXEC));
    proc_exit(1);
  }

  hex_decode(secret_buf, secret_len, VARDATA(secret_key));
  SET_VARSIZE(secret_key, 32 + VARHDRSZ); /* actual length */

  free(secret_buf);
  elog(LOG, "vault primary server secret key loaded");
}

PG_FUNCTION_INFO_V1(_get_secret_key);
Datum _get_secret_key(PG_FUNCTION_ARGS) {
  PG_RETURN_BYTEA_P(secret_key);
}
