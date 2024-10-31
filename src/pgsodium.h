#ifndef PGSODIUM_H
#define PGSODIUM_H

#include <postgres.h>

#include <stdio.h>
#include <sodium.h>
#include <unistd.h>
#include <stdbool.h>
#include <stdlib.h>
#include <fmgr.h>
#if PG_VERSION_NUM >= 160000
#include <varatt.h>
#endif

#define elogn(s) elog(NOTICE, "%s", (s))
#define elogn1(s, v) elog(NOTICE, "%s: %lu", (s), (v))

#define PG_GETKEY_EXEC "pgsodium_getkey"

#define PGSODIUM_UCHARDATA(_vlena) (unsigned char *)VARDATA(_vlena)
#define PGSODIUM_CHARDATA(_vlena) (char *)VARDATA(_vlena)

#define PGSODIUM_UCHARDATA_ANY(_vlena) (unsigned char *)VARDATA_ANY(_vlena)
#define PGSODIUM_CHARDATA_ANY(_vlena) (char *)VARDATA_ANY(_vlena)

#define ERRORIF(B, msg)                                                        \
    if ((B))                                                                   \
        ereport(ERROR, (errcode(ERRCODE_DATA_EXCEPTION), errmsg(msg, __func__)))

typedef struct _pgsodium_cb
{
	void       *ptr;
	size_t      size;
} _pgsodium_cb;

static void context_cb_zero_buff (void *);

static void
context_cb_zero_buff (void *a)
{
	_pgsodium_cb *data = (_pgsodium_cb *) a;
	sodium_memzero (data->ptr, data->size);
}

static inline bytea *_pgsodium_zalloc_bytea (size_t);
static inline bytea *pgsodium_derive_helper (unsigned long long subkey_id,
	size_t subkey_size, bytea * context);

extern bytea *pgsodium_secret_key;
extern char *getkey_script;

/* allocator attached zero-callback to clean up memory */
static inline bytea *
_pgsodium_zalloc_bytea (size_t allocation_size)
{
	bytea      *result = (bytea *) palloc (allocation_size);
	MemoryContextCallback *ctxcb =
		(MemoryContextCallback *) MemoryContextAlloc (CurrentMemoryContext,
		sizeof (MemoryContextCallback));
	_pgsodium_cb *d = (_pgsodium_cb *) palloc (sizeof (_pgsodium_cb));
	d->ptr = result;
	d->size = allocation_size;
	ctxcb->func = context_cb_zero_buff;
	ctxcb->arg = d;
	MemoryContextRegisterResetCallback (CurrentMemoryContext, ctxcb);	// verify where this cb fires
	SET_VARSIZE (result, allocation_size);
	return result;
}

static inline text *
_pgsodium_zalloc_text (size_t allocation_size)
{
	text       *result = (text *) palloc (allocation_size);
	MemoryContextCallback *ctxcb =
		(MemoryContextCallback *) MemoryContextAlloc (CurrentMemoryContext,
		sizeof (MemoryContextCallback));
	_pgsodium_cb *d = (_pgsodium_cb *) palloc (sizeof (_pgsodium_cb));
	d->ptr = result;
	d->size = allocation_size;
	ctxcb->func = context_cb_zero_buff;
	ctxcb->arg = d;
	MemoryContextRegisterResetCallback (CurrentMemoryContext, ctxcb);
	SET_VARSIZE (result, allocation_size);
	return result;
}

static inline bytea *
pgsodium_derive_helper (unsigned long long subkey_id,
	size_t subkey_size, bytea * context)
{
	size_t      result_size;
	bytea      *result;
	ERRORIF (pgsodium_secret_key == NULL,
		"%s: pgsodium_derive: no server secret key defined.");
	ERRORIF (subkey_size < crypto_kdf_BYTES_MIN ||
		subkey_size > crypto_kdf_BYTES_MAX,
		"%s: crypto_kdf_derive_from_key: invalid key size requested");
	ERRORIF (VARSIZE_ANY_EXHDR (context) != 8,
		"%s: crypto_kdf_derive_from_key: context must be 8 bytes");
	result_size = VARHDRSZ + subkey_size;
	result = _pgsodium_zalloc_bytea (result_size);
	crypto_kdf_derive_from_key (PGSODIUM_UCHARDATA (result),
		subkey_size,
		subkey_id,
		(const char *) VARDATA_ANY (context),
		PGSODIUM_UCHARDATA (pgsodium_secret_key));
	return result;
}

#endif /* PGSODIUM_H */
