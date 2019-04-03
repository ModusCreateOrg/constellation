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
. "$BASE_DIR/env.sh"
# shellcheck disable=SC1090
. "$DIR/common-docker.sh"
# shellcheck disable=SC1090
. "$DIR/common-awscli.sh"
# shellcheck disable=SC1090
. "$DIR/common-k8s.sh"
# shellcheck disable=SC1090
. "$DIR/common-helm.sh"
# shellcheck disable=SC1090
. "$DIR/build-help.sh"

# PROJECT WIDE VARS
CLUSTER_NAME="$(k8s-get-cluster-name)"
export CLUSTER_NAME


# GET ARGS
op=${1:-build}
shift
args=${*:-all}

#echo "OP: ${op}"
#echo "ARGS: ${args}"

case "${op}" in

# Display the help
help)
	print-help
	exit 0
    ;; 

# List all of the PODs in the cluster
list-pods)
   	k8s-list-pods
 	exit 0
   	;;

# List all of the PODs in the cluster
list-svcs)
   	k8s-list-svcs
 	exit 0
   	;;

# Update the kubeconfig in your home dir.
kubeconfig)
   	k8s-update-kubeconfig-home
 	exit 0
   	;;

# Create the cluster dashboard and admin user.
create-dashboard)
      k8s-create-dashboard
      k8s-create-admin
   exit 0
      ;;

# Install the metrics server on the cluster
install-metrics-server)
      k8s-install-metrics-server
   exit 0
      ;;

# Open a proxy to the dashboard.
proxy-dashboard)
      k8s-proxy-dashboard
   exit 0
      ;;

# Delete all apps
delete-all)
   	k8s-delete-all
 	exit 0
   	;;

# Configure the cluster autoscaling
enable-cluster-autoscaling)
   	helm-enable-cluster-autoscaling
 	exit 0
   	;;

esac

if [ "${args}" == "all" ]; then
	if [ "${op}" == "run" ] || [ "${op}" == "shell" ]; then
		echo "Can't run the command (${op}) for all applications!"
		exit 1
	fi
	dirs=$(find "${BASE_DIR}/applications" -type d -maxdepth 1 -exec basename {} \; | grep -v applications | grep -v '^_')
	for dir in ${dirs}; do
   		# shellcheck disable=SC1090
		. "${DIR}/build-app.sh" "${dir}" "${op}"
	done
else
	# shellcheck disable=SC2068
	for dir in ${args} ; do
   		# shellcheck disable=SC1090
		. "${DIR}/build-app.sh" "${dir}" "${op}"
	done
fi