#!/bin/bash

set -e

DB_HOST="supabase_vault-test-db"
DB_NAME="postgres"
SU="postgres"
EXEC="docker exec $DB_HOST"

echo building test image
docker build . --force-rm -t supabase_vault/test

echo running test container
docker run -d --name "$DB_HOST" -e POSTGRES_PASSWORD=password supabase_vault/test 

echo waiting for database to accept connections
until
    $EXEC \
	    psql -o /dev/null -t -q -h localhost -U "$SU" \
        -c 'select pg_sleep(1)' \
	    2>/dev/null;
do sleep 1;
done

echo running tests
$EXEC pg_prove -U "$SU" -h localhost /vault/test.sql

echo destroying test container and image
docker rm --force "$DB_HOST"
docker rmi supabase_vault/test
