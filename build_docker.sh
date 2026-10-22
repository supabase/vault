#! /bin/bash
set -eoux pipefail

docker build --tag vault_rocky .
container_id=$(
	docker container create \
		vault_rocky:latest
)
docker cp ./ "${container_id}":/home/vault/vault
docker start --attach "${container_id}"
