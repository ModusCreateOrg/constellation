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

function k8s-get-cluster-name(){
	echo "${PROJECT_NAME}-cluster"
}

function k8s-get-kubeconfig-dir(){
	dir="${BASE_DIR}/.kube"
	mkdir -p "${dir}"
	echo "${dir}"
}

function k8s-update-kubeconfig-home(){
	aws eks update-kubeconfig --region "${AWS_DEFAULT_REGION}" --name "${CLUSTER_NAME}"
}

function k8s-update-kubeconfig(){
	rm  -f "$(k8s-get-kubeconfig-dir)/config"
	aws eks update-kubeconfig --kubeconfig "$(k8s-get-kubeconfig-dir)/config" --region "${AWS_DEFAULT_REGION}" --name "${CLUSTER_NAME}"
}

function k8s-kube-ctl(){
	k8s-update-kubeconfig
	# shellcheck disable=SC2068
	kubectl "--kubeconfig=$(k8s-get-kubeconfig-dir)/config" $@
}

function k8s-list-pods(){
	k8s-kube-ctl get pods --all-namespaces
}

function k8s-list-svcs(){
	k8s-kube-ctl get services
}

function k8s-describe-pod(){
	k8s-kube-ctl describe pods "${IMAGE_NAME}"
}

function k8s-deploy(){
	echo "INFO: k83-deploy:" "${IMAGE_NAME}:${IMAGE_VERSION} --> ${IMAGE_NAME}"
	k8s-kube-ctl run "${IMAGE_NAME}" "--port=${CONTAINER_PORT}" --image "${REPOSITORY_BASE}/${IMAGE_NAME}:${IMAGE_VERSION}"
	k8s-kube-ctl expose deployment "${IMAGE_NAME}" --type=LoadBalancer "--port=${EXPOSE_PORT}" "--target-port=${CONTAINER_PORT}"
}

function k8s-update(){
	echo "INFO: k83-update:" "${IMAGE_NAME}:${IMAGE_VERSION} --> ${IMAGE_NAME}"
	k8s-kube-ctl set image "deployment/${IMAGE_NAME}" "${IMAGE_NAME}=${REPOSITORY_BASE}/${IMAGE_NAME}:${IMAGE_VERSION}"
}

function k8s-delete(){
	echo "INFO: k83-delete:" "${IMAGE_NAME}"
	k8s-kube-ctl delete deployment "${IMAGE_NAME}"
	k8s-kube-ctl delete svc "${IMAGE_NAME}"
}

function k8s-initialize(){
	echo "INFO: k83-initialize"
	echo k8s-initialize
}





