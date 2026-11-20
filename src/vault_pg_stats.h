#ifndef VAULT_PG_STATS_H
#define VAULT_PG_STATS_H
 
#include "postgres.h"
#include "access/htup_details.h"
#include "funcapi.h"
#include "utils/builtins.h"
#include "utils/timestamp.h"
#if PG_VERSION_NUM >= 180000
#include "pgstat.h"
#include "utils/pgstat_internal.h"

/*
 * Kind ID for test_custom_fixed_stats.
 */
#define PGSTAT_KIND_VAULT_STATS 26

/* Fixed-amount custom statistics entry */
typedef struct VaultPgStat_StatVaultEntry
{
       PgStat_Counter encryption_count;        /* # of times update function called */
       PgStat_Counter decryption_count;        /* # of times update function called */
       TimestampTz stat_reset_timestamp;
} VaultPgStat_StatVaultEntry;

typedef struct VaultPgStatShared_VaultEntry
{
       LWLock          lock;                   /* protects counters */
       uint32          changecount;    /* for atomic reads */
       VaultPgStat_StatVaultEntry stats;     /* current counters */
       VaultPgStat_StatVaultEntry reset_offset;      /* reset baseline */
} VaultPgStatShared_VaultEntry;

/* Callbacks for fixed-amount statistics */
void vault_stats_vault_init_shmem_cb(void *stats);
void vault_stats_vault_reset_all_cb(TimestampTz ts);
void vault_stats_vault_snapshot_cb(void);

extern void vault_register_stats(void);

extern void stats_vault_encryption_update(void);
extern void stats_vault_decryption_update(void);

#endif
#endif
