version=$1
shift

DB_HOST="vault-test-db-$version"
DB_NAME="postgres"
SU="postgres"
EXEC="docker exec $DB_HOST"
TAG="vault/test-$version"
CONFIG="-c shared_preload_libraries=pgsodium -c pgsodium.getkey_script=/pgsodium/getkey_scripts/pgsodium_getkey_urandom.sh"
EXPORT=6789

echo building test image $DB_HOST
docker build . -t $TAG --build-arg "version=$version"

echo running test container
docker run \
	   -v `pwd`:/vault \
	   -e POSTGRES_HOST_AUTH_METHOD=trust \
	   -d --name "$DB_HOST" $TAG $CONFIG

echo waiting for database to accept connections
until
    $EXEC \
        psql -o /dev/null -t -q -U "$SU" \
        -c 'select pg_sleep(1)' \
        2>/dev/null;
do sleep 1;
done

echo running tests
$EXEC psql -q -U "$SU" -f /vault/test.sql
