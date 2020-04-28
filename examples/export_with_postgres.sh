#!/bin/sh

set -eu
export LC_ALL=C

DOCKER=$(command -v docker 2>/dev/null)

IMAGE_REGISTRY=repo.stratebi.com
IMAGE_NAMESPACE=lincebi
IMAGE_PROJECT=biserver
IMAGE_TAG=8.2.0.0-342
IMAGE_NAME=${IMAGE_REGISTRY:?}/${IMAGE_NAMESPACE:?}/${IMAGE_PROJECT:?}:${IMAGE_TAG:?}
CONTAINER_NAME=${IMAGE_PROJECT:?}-export

"${DOCKER:?}" run --rm \
	--name "${CONTAINER_NAME:?}" \
	--hostname "${CONTAINER_NAME:?}" \
	--env STORAGE_TYPE='postgres' \
	--env POSTGRES_HOST='localhost' \
	--env POSTGRES_PORT='5432' \
	--env POSTGRES_USER='postgres' \
	--env POSTGRES_PASSWORD='postgres' \
	--env POSTGRES_DATABASE='postgres' \
	--env POSTGRES_JACKRABBIT_USER='jcr_user' \
	--env POSTGRES_JACKRABBIT_PASSWORD='jcr_password' \
	--env POSTGRES_JACKRABBIT_DATABASE='jackrabbit' \
	--env POSTGRES_HIBERNATE_USER='hibuser' \
	--env POSTGRES_HIBERNATE_PASSWORD='hibpassword' \
	--env POSTGRES_HIBERNATE_DATABASE='hibernate' \
	--env POSTGRES_QUARTZ_USER='pentaho_user' \
	--env POSTGRES_QUARTZ_PASSWORD='pentaho_password' \
	--env POSTGRES_QUARTZ_DATABASE='quartz' \
	"${IMAGE_NAME:?}" /usr/share/biserver/bin/export.sh
