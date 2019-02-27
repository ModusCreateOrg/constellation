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

# BUILD FLAGS
export IS_DEPLOYABLE="true"

# APPLICATION
export APPLICATION_NAME=prometheus
export IMAGE_NAME=prometheus
export IMAGE_VERSION=latest
export REPOSITORY_BASE="prom"

# PORTS
export HAS_PORT="true"
export CONTAINER_PORT="9090"
export LOCAL_HOST_PORT=8082
export EXPOSE_PORT=80

# DNS
export HAS_DNS="true"
export APP_HOSTED_ZONE_ID="ZC5W4OMO7VFXP" # devops-eks-demo.modus.app
export APP_DOMAIN_NAME="eks-demo-prom.modus.app"

# HEALTH CHECK
export SET_HEALTH_CHECK='true'
export HEALTH_CHECK_TYPE='http'
export HEALTH_CHECK_PATH='/metrics'