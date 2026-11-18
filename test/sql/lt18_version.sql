-- Validate correct lib version shows
SHOW vault.version;

-- Validate that user is not able to change version
SET vault.version to 'v0.0.0';

-- Validate the paramter doesnt show up on pg_settings for pg versions that dont have pg_catalog.pg_get_loaded_modules() function
SELECT name FROM pg_settings WHERE name = 'vault.version';
