#!/usr/bin/env bash
# common-docker.sh

# Only use TTY for Docker if we detect one, otherwise
# this will balk when run in Jenkins
# Thanks https://stackoverflow.com/a/48230089
declare USE_TTY
test -t 1 && USE_TTY="-t" || USE_TTY=""

declare INPUT_ENABLED
test -t 1 && INPUT_ENABLED="true" || INPUT_ENABLED="false"

export INPUT_ENABLED USE_TTY

function docker-build(){
	echo DOCKER BUILD: "${IMAGE_NAME}:${IMAGE_VERSION}"
	docker build \
		-t "${IMAGE_NAME}:${IMAGE_VERSION}" \
		-t "${REPOSITORY_BASE}/${IMAGE_NAME}:${IMAGE_VERSION}" \
		.
}

function docker-push(){
	echo DOCKER PUSH: "${REPOSITORY_BASE}/${IMAGE_NAME}:${IMAGE_VERSION}"
	# shellcheck disable=SC2091
	$(aws ecr get-login --no-include-email)
	docker push "${REPOSITORY_BASE}/${IMAGE_NAME}:${IMAGE_VERSION}"
}

function docker-run(){
	echo DOCKER RUN: "${IMAGE_NAME}:${IMAGE_VERSION}"
	if [ "${HAS_PORT}" == 'true' ]; then
		echo "   local:${HOST_PORT} '-->' container:${CONTAINER_PORT}"
		docker run -p "${HOST_PORT}:${CONTAINER_PORT}" -it "${IMAGE_NAME}:${IMAGE_VERSION}"
	else
		docker run -it "${IMAGE_NAME}:${IMAGE_VERSION}"
	fi
}

function docker-shell(){
	echo DOCKER SHELL: "${IMAGE_NAME}:${IMAGE_VERSION}"
	if [ "${HAS_PORT}" == 'true' ]; then
		echo "   local:${HOST_PORT} '-->' container:${CONTAINER_PORT}"
		docker run -p "${HOST_PORT}:${CONTAINER_PORT}" -it "${IMAGE_NAME}:${IMAGE_VERSION}" /usr/bin/bash
	else
		docker run -it "${IMAGE_NAME}:${IMAGE_VERSION}" /usr/bin/bash
	fi
}

