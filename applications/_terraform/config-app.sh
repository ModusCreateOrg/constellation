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

export IS_DEPLOYABLE="false"
export HAS_PORT="false"

export APPLICATION_NAME=terraform
export IMAGE_NAME=terraform
export IMAGE_VERSION=0.11.11
export REPOSITORY_BASE="moduscreate"