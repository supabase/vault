-- Search pg_temp last so callers can't shadow types (e.g. text, bytea) with temp objects that run as the function owner (PSQLEXT-1780).
ALTER FUNCTION vault.create_secret(text, text, text, uuid) SET search_path = pg_catalog, pg_temp;
ALTER FUNCTION vault.update_secret(uuid, text, text, text, uuid) SET search_path = pg_catalog, pg_temp;
