SELECT * FROM pg_catalog.pg_get_loaded_modules();

-- Validate the deprecated parameter doesnt show up on pg_settings
SELECT name FROM pg_settings WHERE name = 'supautils.version';
