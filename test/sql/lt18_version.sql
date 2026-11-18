
-- Validate the paramter doesnt show up on pg_settings for pg versions that dont have pg_catalog.pg_get_loaded_modules() function
SELECT name FROM pg_settings WHERE name = 'supautils.version';
