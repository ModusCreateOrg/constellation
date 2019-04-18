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
export IS_BUILDABLE="true"
export IS_DEPLOYABLE="true"

# APPLICATION
export APPLICATION_NAME=webapp
export IMAGE_NAME=k8s-dev-webapp
export IMAGE_VERSION=1.0.3
export REPOSITORY_BASE="976851222302.dkr.ecr.us-west-2.amazonaws.com/k8s-eks-scaling-demo-repo"

# PORTS
export HAS_PORT="true"
export CONTAINER_PORT="80"
export LOCAL_HOST_PORT=8081
export EXPOSE_PORT=80

# DNS
export HAS_DNS="true"
export APP_HOSTED_ZONE_ID="ZXRWF072FZRRS"
export APP_DOMAIN_NAME="eks-demo-webapp.moduscreate.com"

# SCALING
export HAS_APP_SCALING=true
export APP_SCALE_CPU_PERCENT=50
export APP_SCALE_MIN=1
export APP_SCALE_MAX=100
