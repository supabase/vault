#include "vault_pg_stats.h"
#if PG_VERSION_NUM >= 180000

static const PgStat_KindInfo vault_stats = {
       .name = "vault_stats",
       .fixed_amount = true,           /* exactly one entry */
       .write_to_file = true,          /* persist to stats file */

       .shared_size = sizeof(VaultPgStatShared_VaultEntry),
       .shared_data_off = offsetof(VaultPgStatShared_VaultEntry, stats),
       .shared_data_len = sizeof(((VaultPgStatShared_VaultEntry *) 0)->stats),

       .init_shmem_cb = vault_stats_vault_init_shmem_cb,
       .reset_all_cb = vault_stats_vault_reset_all_cb,
       .snapshot_cb = vault_stats_vault_snapshot_cb,
};

void vault_register_stats (void) {
  pgstat_register_kind(PGSTAT_KIND_VAULT_STATS, &vault_stats);
}

/*
 * test_custom_stats_fixed_init_shmem_cb
 *             Initialize shared memory structure
 */
void
vault_stats_vault_init_shmem_cb(void *stats)
{
       VaultPgStatShared_VaultEntry *stats_shmem =
               (VaultPgStatShared_VaultEntry *) stats;

       LWLockInitialize(&stats_shmem->lock, LWTRANCHE_PGSTATS_DATA);
}

/*
 * test_custom_stats_fixed_reset_all_cb
 *             Reset the fixed-sized stats
 */
void
vault_stats_vault_reset_all_cb(TimestampTz ts)
{
       VaultPgStatShared_VaultEntry *stats_shmem =
               pgstat_get_custom_shmem_data(PGSTAT_KIND_VAULT_STATS);

       /* see explanation above PgStatShared_Archiver for the reset protocol */
       LWLockAcquire(&stats_shmem->lock, LW_EXCLUSIVE);
       pgstat_copy_changecounted_stats(&stats_shmem->reset_offset,
                                                                       &stats_shmem->stats,
                                                                       sizeof(stats_shmem->stats),
                                                                       &stats_shmem->changecount);
       stats_shmem->stats.stat_reset_timestamp = ts;
       LWLockRelease(&stats_shmem->lock);
}

/*
 * test_custom_stats_fixed_snapshot_cb
 *             Copy current stats to snapshot area
 */
void
vault_stats_vault_snapshot_cb(void)
{
       VaultPgStatShared_VaultEntry *stats_shmem =
               pgstat_get_custom_shmem_data(PGSTAT_KIND_VAULT_STATS);
       VaultPgStat_StatVaultEntry *stat_snap =
               pgstat_get_custom_snapshot_data(PGSTAT_KIND_VAULT_STATS);
       VaultPgStat_StatVaultEntry *reset_offset = &stats_shmem->reset_offset;
       VaultPgStat_StatVaultEntry reset;

       pgstat_copy_changecounted_stats(stat_snap,
                                                                       &stats_shmem->stats,
                                                                       sizeof(stats_shmem->stats),
                                                                       &stats_shmem->changecount);

       LWLockAcquire(&stats_shmem->lock, LW_SHARED);
       memcpy(&reset, reset_offset, sizeof(stats_shmem->stats));
       LWLockRelease(&stats_shmem->lock);

       /* Apply reset offsets */
#define FIXED_COMP(fld) stat_snap->fld -= reset.fld;
       FIXED_COMP(encryption_count);
       FIXED_COMP(decryption_count);
#undef FIXED_COMP
}

void stats_vault_encryption_update(void){
  VaultPgStatShared_VaultEntry *stats_shmem;
  stats_shmem = pgstat_get_custom_shmem_data(PGSTAT_KIND_VAULT_STATS);
  LWLockAcquire(&stats_shmem->lock, LW_EXCLUSIVE);
  pgstat_begin_changecount_write(&stats_shmem->changecount);
  stats_shmem->stats.encryption_count++;
  pgstat_end_changecount_write(&stats_shmem->changecount);
  LWLockRelease(&stats_shmem->lock);
}

void stats_vault_decryption_update(void){
  VaultPgStatShared_VaultEntry *stats_shmem;
  stats_shmem = pgstat_get_custom_shmem_data(PGSTAT_KIND_VAULT_STATS);
  LWLockAcquire(&stats_shmem->lock, LW_EXCLUSIVE);
  pgstat_begin_changecount_write(&stats_shmem->changecount);
  stats_shmem->stats.decryption_count++;
  pgstat_end_changecount_write(&stats_shmem->changecount);
  LWLockRelease(&stats_shmem->lock);
}

/*
 * test_custom_stats_fixed_reset
 *		Reset statistics by calling pgstat system
 */
PG_FUNCTION_INFO_V1(pg_stat_vault_reset);
Datum
pg_stat_vault_reset(PG_FUNCTION_ARGS)
{
	pgstat_reset_of_kind(PGSTAT_KIND_VAULT_STATS);

	PG_RETURN_VOID();
}


PG_FUNCTION_INFO_V1(pg_stat_vault);
Datum
pg_stat_vault(__attribute__((unused)) PG_FUNCTION_ARGS)
{
       TupleDesc       tupdesc;
       Datum           values[3] = {0, 0};
       bool            nulls[3] = {false, false};
       VaultPgStat_StatVaultEntry *stats;

       /* Take snapshot (applies reset offsets) */
       pgstat_snapshot_fixed(PGSTAT_KIND_VAULT_STATS);
       stats = pgstat_get_custom_snapshot_data(PGSTAT_KIND_VAULT_STATS);

       /* Build return tuple */
       tupdesc = CreateTemplateTupleDesc(3);
       TupleDescInitEntry(tupdesc, (AttrNumber) 1, "encryption_count",
                                          INT8OID, -1, 0);
       TupleDescInitEntry(tupdesc, (AttrNumber) 2, "decryption_count",
                                          INT8OID, -1, 0);
       TupleDescInitEntry(tupdesc, (AttrNumber) 3, "stats_reset",
                                          TIMESTAMPTZOID, -1, 0);
#if PG_VERSION_NUM >= 190000
       TupleDescFinalize(tupdesc);
#endif
       BlessTupleDesc(tupdesc);

       values[0] = Int64GetDatum(stats->encryption_count);
       values[1] = Int64GetDatum(stats->decryption_count);

       /* Handle uninitialized timestamp (no reset yet) */
       if (stats->stat_reset_timestamp == 0)
       {
               nulls[2] = true;
       }
       else
       {
               values[2] = TimestampTzGetDatum(stats->stat_reset_timestamp);
       }

       /* Return as tuple */
       PG_RETURN_DATUM(HeapTupleGetDatum(heap_form_tuple(tupdesc, values, nulls)));
}
#else

PG_FUNCTION_INFO_V1(pg_stat_vault);
Datum
pg_stat_vault(__attribute__((unused)) PG_FUNCTION_ARGS)
{
       TupleDesc       tupdesc;
       Datum           values[3] = {0, 0, 0};
       bool            nulls[3] = {false, false, false};

       /* Build return tuple */
       tupdesc = CreateTemplateTupleDesc(3);
       TupleDescInitEntry(tupdesc, (AttrNumber) 1, "encryption_count",
                                          INT8OID, -1, 0);
       TupleDescInitEntry(tupdesc, (AttrNumber) 2, "decryption_count",
                                          INT8OID, -1, 0);
       TupleDescInitEntry(tupdesc, (AttrNumber) 3, "stats_reset",
                                          TIMESTAMPTZOID, -1, 0);
#if PG_VERSION_NUM >= 190000
       TupleDescFinalize(tupdesc);
#endif
       BlessTupleDesc(tupdesc);

       /* Return as tuple */
       PG_RETURN_DATUM(HeapTupleGetDatum(heap_form_tuple(tupdesc, values, nulls)));
}

/*
 * test_custom_stats_fixed_reset
 *		Reset statistics by calling pgstat system
 */
PG_FUNCTION_INFO_V1(pg_stat_vault_reset);
Datum
pg_stat_vault_reset(PG_FUNCTION_ARGS)
{
	PG_RETURN_VOID();
}


#endif
