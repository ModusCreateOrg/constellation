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
	env=$1;	app=$2; ver=$3
	image-name "${env}" "${app}" "${ver}" 
	echo DOCKER BUILD: "${IMAGE_NAME}"
	docker build \
		-t "${IMAGE_NAME}" \
		-t "${REPO_BASE_URI}/${IMAGE_NAME}" \
		.
}

function docker-push(){
	env=$1; app=$2; ver=$3
	image-name "${env}" "${app}" "${ver}" 

	echo DOCKER PUSH: "${IMAGE_NAME}"
	# shellcheck disable=SC2091
	$(aws ecr get-login --no-include-email)
	docker push "${REPO_BASE_URI}/${IMAGE_NAME}"
}

function docker-run(){
	base=$1; env=$2; app=$3; ver=$4
	image-name "${env}" "${app}" "${ver}" 

	echo DOCKER RUN: "${IMAGE_NAME}"
	echo "   local:${base}080 '-->' container:80"
	docker run \
		-p "${base}080:80" \
		-it "${IMAGE_NAME}"
}

function docker-shell(){
	env=$1; app=$2; ver=$3; base=$4
	image-name "${env}" "${app}" "${ver}" 

	echo DOCKER SHELL: "${IMAGE_NAME}"
	echo "   local:${base}080 '-->' container:80"
	docker run \
		-p "${base}080:80" \
		-it "${IMAGE_NAME}" \
		/usr/bin/bash
}

function docker-deploy(){
	env=$1; app=$2; ver=$3
	image-name "${env}" "${app}" "${ver}" 

	echo DOCKER DEPLOY: "${IMAGE_NAME}"
	# shellcheck disable=SC2091
	$(aws eks --region "us-west-2" update-kubeconfig --name "k8s-eks-scaling-demo-cluster")
}

