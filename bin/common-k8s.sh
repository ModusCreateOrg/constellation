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

function k8s-create-dashboard(){
    k8s-kube-ctl create -f https://raw.githubusercontent.com/kubernetes/dashboard/master/aio/deploy/recommended/kubernetes-dashboard.yaml
}

function k8s-proxy-dashboard(){
    k8s-kube-ctl -n kube-system describe secret "$(kubectl -n kube-system get secret | grep admin-user | awk '{print $1}')"
    cat <<- EOF
    ==========================

    Use the "token:" above to login after you connect to the dashboard here:
     
        http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/

    ===========================
EOF
    k8s-kube-ctl proxy
}

function k8s-create-admin(){
    k8s-kube-ctl apply -f "${BASE_DIR}/config/dashboard-adminuser.yaml"
    k8s-kube-ctl -n kube-system describe secret "$(kubectl -n kube-system get secret | grep admin-user | awk '{print $1}')"
}

function k8s-run-app(){
    echo "INFO: k83-deploy-app:" "${IMAGE_NAME}:${IMAGE_VERSION} --> ${IMAGE_NAME}"
    k8s-kube-ctl run "${IMAGE_NAME}" "--port=${CONTAINER_PORT}" --image "${REPOSITORY_BASE}/${IMAGE_NAME}:${IMAGE_VERSION}" "--limits=cpu=200m,memory=512Mi"
}

function k8s-expose-app(){
    echo "INFO: k83-expose-app:" "${IMAGE_NAME}:${IMAGE_VERSION} --> ${IMAGE_NAME}"
    k8s-kube-ctl expose deployment "${IMAGE_NAME}" --type=LoadBalancer "--port=${EXPOSE_PORT}" "--target-port=${CONTAINER_PORT}"

}

function k8s-autoscale-app(){
    echo "INFO: k8s-autoscale-app:" "${IMAGE_NAME}:${IMAGE_VERSION} --> ${IMAGE_NAME}"
    k8s-kube-ctl autoscale deployment "${IMAGE_NAME}" "--cpu-percent=${APP_SCALE_CPU_PERCENT}" "--min=${APP_SCALE_MIN}" "--max=${APP_SCALE_MAX}"
}

function k8s-update-app(){
    echo "INFO: k83-update:" "${IMAGE_NAME}:${IMAGE_VERSION} --> ${IMAGE_NAME}"
    k8s-kube-ctl set image "deployment/${IMAGE_NAME}" "${IMAGE_NAME}=${REPOSITORY_BASE}/${IMAGE_NAME}:${IMAGE_VERSION}"
}

function k8s-delete-app(){
    echo "INFO: k8s-delete-app:" "${IMAGE_NAME}"
    k8s-kube-ctl delete deployment "${IMAGE_NAME}"
}

function k8s-install-metrics-server(){
    echo "INFO: k8s-add-metrics-server"
    rm -rf "${BASE_DIR}/metrics-server"
    cd "${BASE_DIR}" || exit 1
    git clone https://github.com/kubernetes-incubator/metrics-server.git
    cd "${BASE_DIR}/metrics-server" || exit 1
    k8s-kube-ctl create -f deploy/1.8+/
    #k8s-kube-ctl create -f deploy/1.7/
    k8s-kube-ctl get deployment metrics-server -n kube-system
}

function k8s-delete-app-expose(){
    echo "INFO: k8s-delete-expose:" "${IMAGE_NAME}"
    k8s-kube-ctl delete svc "${IMAGE_NAME}"
}

function k8s-delete-app-autoscale(){
    echo "INFO: k8s-delete-expose:" "${IMAGE_NAME}"
    k8s-kube-ctl delete hpa "${IMAGE_NAME}"
}

function k8s-delete-all(){
    echo "INFO: k8s-delete-all"
    # Thanks Stack Overflow: https://stackoverflow.com/a/43996070
    # k8s-kube-ctl get pods --no-headers=true --all-namespaces |sed -r 's/(\S+)\s+(\S+).*/kubectl --namespace \1 delete pod \2/e'
    k8s-kube-ctl delete daemonsets,replicasets,services,deployments,pods,rc --all

}





