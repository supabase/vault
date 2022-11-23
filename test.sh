#!/bin/bash

set -e

DB_HOST="supabase_vault-test-db"
DB_NAME="postgres"
SU="postgres"
EXEC="docker exec $DB_HOST"
CONFIG="-c shared_preload_libraries=pgsodium -c pgsodium.getkey_script=/pgsodium/getkey_scripts/pgsodium_getkey_urandom.sh"

echo building test image
docker build . --force-rm -t supabase_vault/test

echo running test container
docker run -d --name "$DB_HOST" -e POSTGRES_PASSWORD=password supabase_vault/test $CONFIG

echo waiting for database to accept connections
until
    $EXEC \
	    psql -o /dev/null -t -q -h localhost -U "$SU" \
        -c 'select pg_sleep(1)' \
	    2>/dev/null;
do sleep 1;
done

echo running tests
$EXEC psql -q -U "$SU" -f /vault/test.sql

echo destroying test container and image
docker rm --force "$DB_HOST"
docker rmi supabase_vault/test
