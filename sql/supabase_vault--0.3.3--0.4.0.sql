
CREATE FUNCTION pg_stat_vault(OUT encryption_count bigint, 
    OUT decryption_count bigint,
    OUT stats_reset timestamptz)
RETURNS record
AS 'MODULE_PATHNAME', 'pg_stat_vault'
LANGUAGE C STRICT PARALLEL UNSAFE;


CREATE FUNCTION pg_stat_vault_reset()
RETURNS void
AS 'MODULE_PATHNAME', 'pg_stat_vault_reset'
LANGUAGE C STRICT PARALLEL UNSAFE;
