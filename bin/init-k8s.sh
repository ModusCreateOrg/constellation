#!/usr/bin/env bash
# Prepare a clean environment

# Set bash unofficial strict mode http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail

# Enable for enhanced debugging
#set -vx
# Credit to https://stackoverflow.com/a/17805088
# and http://wiki.bash-hackers.org/scripting/debuggingtips
export PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'

# Credit to http://stackoverflow.com/a/246128/424301
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BASE_DIR="$DIR/.."

# shellcheck disable=SC1090
. "$DIR/common-k8s.sh"
# shellcheck disable=SC1090
. "$BASE_DIR/env.sh"
# shellcheck disable=SC1090
. "$BASE_DIR/config/k8s.sh"

APP_NAME=echoserver

aws eks --region "${AWS_DEFAULT_REGION}" update-kubeconfig --name "${CLUSTER_NAME}"

kubectl apply -f "${BASE_DIR}/config/rbac-role.yaml"
kubectl apply -f "${BASE_DIR}/config/alb-ingress-controller.yaml"

# DEBUG
#kubectl logs -n kube-system "$(kubectl get po -n kube-system | egrep -o alb-ingress[a-zA-Z0-9-]+)"

kubectl apply -f "${BASE_DIR}/config/${APP_NAME}/namespace.yaml"
kubectl apply -f "${BASE_DIR}/config/${APP_NAME}/service.yaml"
kubectl apply -f "${BASE_DIR}/config/${APP_NAME}/deployment.yaml"

# DEBUG
#kubectl get -n echoserver deploy,svc

kubectl apply -f "${BASE_DIR}/config/${APP_NAME}/ingress.yaml"

# DEBUG
#kubectl logs -n kube-system "$(kubectl get po -n kube-system | egrep -o 'alb-ingress[a-zA-Z0-9-]+')" # | grep 'echoserver\/echoserver'
#kubectl describe ing -n echoserver echoserver

kubectl apply -f "${BASE_DIR}/config/${APP_NAME}/external-dns.yaml"
# DEBUG
#dig k8s-eks-scaling-demo-echo.modus.app
#curl http://k8s-eks-scaling-demo-echo.modus.app
