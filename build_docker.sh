#! /bin/bash
set -eoux pipefail

BASE_IMAGE=$1

docker build \
	--build-arg=BASE_IMAGE="${BASE_IMAGE}" \
	--tag vault_rocky \
	.

container_id=$(
	docker container create \
		vault_rocky:latest
)

docker cp \
	./ \
	"${container_id}":/home/postgres/vault

docker start \
	--attach "${container_id}"
