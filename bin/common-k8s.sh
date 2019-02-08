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
	echo K8S DEPLOY: "${IMAGE_NAME}:${IMAGE_VERSION} --> ${IMAGE_NAME}"
	aws eks --region "us-west-2" update-kubeconfig --name "${CLUSTER_NAME}"
	kubectl run "${IMAGE_NAME}" --port=80 --image "${REPOSITORY_BASE}/${IMAGE_NAME}:${IMAGE_VERSION}"
	kubectl expose deployment "${IMAGE_NAME}" --type=LoadBalancer --port=80 --target-port=80
}

function k8s-update(){
	echo K8S UPDATE: "${IMAGE_NAME}:${IMAGE_VERSION} --> ${IMAGE_NAME}"
	aws eks --region "us-west-2" update-kubeconfig --name "${CLUSTER_NAME}"
	kubectl set image "deployment/${IMAGE_NAME}" "${REPOSITORY_BASE}/${IMAGE_NAME}:${IMAGE_VERSION}"
}

function k8s-delete(){
	echo K8S DELETE: "${IMAGE_NAME}"
	aws eks --region "${AWS_DEFAULT_REGION}" update-kubeconfig --name "${CLUSTER_NAME}"
	kubectl delete deployment "${IMAGE_NAME}"
	kubectl delete svc "${IMAGE_NAME}"
}
