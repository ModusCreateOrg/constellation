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
	env=$1; app=$2; ver=$3
	image-name "${env}" "${app}" "${ver}" 
	pod-name "${env}" "${app}"

	echo K8S DEPLOY: "${IMAGE_NAME} --> ${POD_NAME}"
	
	aws eks --region "us-west-2" update-kubeconfig --name "${CLUSTER_NAME}"
	kubectl run "${POD_NAME}" --port=80 --image "${IMAGE_NAME}"
	kubectl expose deployment "${POD_NAME}" --type=LoadBalancer --port=80 --target-port=80
}

function k8s-update(){
	env=$1; app=$2; ver=$3
	image-name "${env}" "${app}" "${ver}" 
	pod-name "${env}" "${app}"

	echo K8S DEPLOY: "${IMAGE_NAME} --> ${POD_NAME}"
	
	aws eks --region "us-west-2" update-kubeconfig --name "${CLUSTER_NAME}"
	kubectl set image "deployment/${POD_NAME}" "${POD_NAME}=${IMAGE_NAME}"
}

function k8s-delete(){
	env=$1; app=$2; ver=$3
	image-name "${env}" "${app}" "${ver}" 
	pod-name "${env}" "${app}"

	echo K8S DEPLOY: "${IMAGE_NAME} --> ${POD_NAME}"
	
	aws eks --region "us-west-2" update-kubeconfig --name "${CLUSTER_NAME}"
	kubectl delete deployment "${POD_NAME}"
	kubectl delete svc "${POD_NAME}"
}
