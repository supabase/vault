-- Validate correct lib version shows
SHOW vault.version;

-- Validate that user is not able to change version
SET vault.version to 'v0.0.0';

SELECT * FROM pg_catalog.pg_get_loaded_modules();

-- Validate the deprecated parameter doesnt show up on pg_settings
SELECT name FROM pg_settings WHERE name = 'vault.version';
