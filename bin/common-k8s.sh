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

function k8s-deploy(){
	dest=$1; env=$2; app=$3; ver=$4
	container-name "${env}" "${app}" "${ver}" 

	echo DOCKER DEPLOY: "${CNAME} --> ${dest}"
	# shellcheck disable=SC2091
	aws eks --region "us-west-2" update-kubeconfig --name "${CLUSTER_NAME}"
}

