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
	dir=$1; env=$2;	app=$3; ver=$4
	container-name "${env}" "${app}" "${ver}" 
	echo DOCKER BUILD: "${CNAME}"
	OCWD=$(pwd)
	cd "${dir}" || exit 1
	docker build \
		-t "${CNAME}" \
		-t "${REPO_BASE_URI}/${CNAME}" \
		.
	cd "${OCWD}" || exit 1
}

function docker-push(){
	env=$1; app=$2; ver=$3
	container-name "${env}" "${app}" "${ver}" 

	echo DOCKER PUSH: "${CNAME}"
	# shellcheck disable=SC2091
	$(aws ecr get-login --no-include-email)
	docker push "${REPO_BASE_URI}/${CNAME}"
}

function docker-run(){
	base=$1; env=$2; app=$3; ver=$4
	container-name "${env}" "${app}" "${ver}" 

	echo DOCKER RUN: "${CNAME}"
	echo "   local:${base}080 '-->' container:80"
	docker run \
		-p "${base}080:80" \
		-it "${CNAME}"
}

function docker-shell(){
	base=$1; env=$2; app=$3; ver=$4
	container-name "${env}" "${app}" "${ver}" 

	echo DOCKER SHELL: "${CNAME}"
	echo "   local:${base}080 '-->' container:80"
	docker run \
		-p "${base}080:80" \
		-it "${CNAME}" \
		/usr/bin/bash
}

function docker-deploy(){
	dest=$1; env=$2; app=$3; ver=$4
	container-name "${env}" "${app}" "${ver}" 

	echo DOCKER DEPLOY: "${CNAME} --> ${dest}"
	# shellcheck disable=SC2091
	$(aws eks --region "us-west-2" update-kubeconfig --name "k8s-eks-scaling-demo-cluster")
}

