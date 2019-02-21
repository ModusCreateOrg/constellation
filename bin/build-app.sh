#!/usr/bin/env bash
# Prepare a clean environment

# Set bash unofficial strict mode http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail

# Set DEBUG to true for enhanced debugging: run prefixed with "DEBUG=true"
${DEBUG:-false} && set -vx
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


CLUSTER_NAME="$(get-cluster-name)"
export CLUSTER_NAME

# ARGS
dir_name=${1:-}
op=${2:-build}

APP_DIR="$BASE_DIR/applications/${dir_name}"
cd "${APP_DIR}" || echo "Can not find: ${APP_DIR}"
echo "Building in: $(pwd)"
# shellcheck disable=SC1091
source ./config-app.sh

  case "$op" in
    # Run this application locally exposing a port if appropriate
    run)
      docker-run
      ;;   
    # Build the image for this application
    build)
      docker-build
      ;;
    # Run this application locally and open a shell. It exposes the port if appropriate.
    shell)
      docker-shell
      ;;
    # Push the image for this application to the repository
    push)
      docker-push
      ;;
    # Deploy this application to the cluster
    deploy)
        if [ "$IS_DEPLOYABLE" == 'true' ]; then  
          k8s-deploy
        else
          echo "This command (${op}) is not a valid operation for a non-deployable application!"
          exit 1
        fi
        ;;
    # Add this application to the DNS
    add-dns)
        if [ "$IS_DEPLOYABLE" == 'true' ]; then  
          add-elb-to-route53
        else
          echo "This command (${op}) is not a valid operation for a non-deployable application!"
          exit 1
        fi
        ;;
    # Update the image for this application which when it is deployed on the cluster
    update)
        if [ "$IS_DEPLOYABLE" == 'true' ]; then  
          k8s-update
        else
          echo "This command (${op}) is not a valid operation for a non-deployable application!"
          exit 1
        fi
        ;;
    # List all of the PODs in the cluster
    list-pods)
        if [ "$IS_DEPLOYABLE" == 'true' ]; then
          k8s-list-pods
        else
          echo "This command (${op}) is not a valid operation for a non-deployable application!"
          exit 1
        fi
        ;;
    # Describe the POD for this application
    describe-pod)
        if [ "$IS_DEPLOYABLE" == 'true' ]; then
          k8s-describe-pod
        else
          echo "This command (${op}) is not a valid operation for a non-deployable application!"
          exit 1
        fi
        ;;
    # Delete this application from the cluster
    delete)
        if [ "$IS_DEPLOYABLE" == 'true' ]; then  
          k8s-delete
        else
          echo "This command (${op}) is not a valid operation for a non-deployable application!"
          exit 1
        fi
      ;;
    # A workspace to run debugging code.
    debug)
        add-elb-to-route53
      ;;
    *)
      echo "This command (${op}) is not a valid operation!"
      exit 1
      ;;
esac

