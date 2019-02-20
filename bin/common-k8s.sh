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

function get-cluster-name(){
	echo "${PROJECT_NAME}-cluster"
}

function get-kubeconfig-dir(){
	dir="${BASE_DIR}/.kube"
	mkdir -p "${dir}"
	echo "${dir}"
}

function update-kubeconfig-home(){
	aws eks update-kubeconfig --region "${AWS_DEFAULT_REGION}" --name "${CLUSTER_NAME}"
}

function update-kubeconfig(){
	rm  -f "$(get-kubeconfig-dir)/config"
	aws eks update-kubeconfig --kubeconfig "$(get-kubeconfig-dir)/config" --region "${AWS_DEFAULT_REGION}" --name "${CLUSTER_NAME}"
}

function kube-ctl(){
	update-kubeconfig
	# shellcheck disable=SC2068
	kubectl "--kubeconfig=$(get-kubeconfig-dir)/config" $@
}

function k8s-list-pods(){
	kube-ctl get pods --all-namespaces
}

function k8s-describe-pod(){
	kube-ctl describe pods "${IMAGE_NAME}"
}

function k8s-deploy(){
	echo K8S DEPLOY: "${IMAGE_NAME}:${IMAGE_VERSION} --> ${IMAGE_NAME}"
	kube-ctl run "${IMAGE_NAME}" --port=80 --image "${REPOSITORY_BASE}/${IMAGE_NAME}:${IMAGE_VERSION}"
	kube-ctl expose deployment "${IMAGE_NAME}" --type=LoadBalancer --port=80 --target-port=80
}

function k8s-update(){
	echo K8S UPDATE: "${IMAGE_NAME}:${IMAGE_VERSION} --> ${IMAGE_NAME}"
	kube-ctl set image "deployment/${IMAGE_NAME}" "${IMAGE_NAME}=${REPOSITORY_BASE}/${IMAGE_NAME}:${IMAGE_VERSION}"
}

function k8s-delete(){
	kube-ctl delete deployment "${IMAGE_NAME}"
	kube-ctl delete svc "${IMAGE_NAME}"
}

