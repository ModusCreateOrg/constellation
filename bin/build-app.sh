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

function reset-app-flags(){
    export IS_BUILDABLE=false
    export IS_DEPLOYABLE=false
    export HAS_PORT=false
    export HAS_HEALTH_CHECK=false
    export HAS_APP_SCALING=false
}

BUILD_DIR="${BASE_DIR}/build"
export BUILD_DIR
mkdir -p "${BUILD_DIR}"

# ARGS
app_dir=${1:-}
app_op=${2:-build}

#echo "INFO: app_dir: ${app_dir}"
#echo "INFO: app_op: ${op}"

# APPLICATION SPECIFIC VARS
APP_DIR="${BASE_DIR}/applications/${app_dir}"
export APP_DIR

# APPLICATION CONFIG
cd "${APP_DIR}" || (echo "Can not find: ${APP_DIR}" && exit 1)
#echo "INFO: Building in: $(pwd)"
reset-app-flags
# shellcheck disable=SC1091
source ./config-app.sh

# CREATE THE APP BUILD DIR
APP_BUILD_DIR="${APP_DIR}/build"
export APP_BUILD_DIR
mkdir -p "${APP_BUILD_DIR}"

# LOAD THE JMETER COMMON. It needs the build dir define above.
# shellcheck disable=SC1090
. "$DIR/common-jmeter.sh"

  case "$app_op" in
    
    # Run this application locally exposing the port if appropriate
    run)
        if [ "${IS_BUILDABLE}" == 'true' ]; then  
          docker-run
        else
          docker-run-external
        fi
        ;; 

    # Run this application locally and open a shell. Exposes the port if appropriate.
    shell)
        docker-shell
        ;;
  
    # Build the image for this application
    build)
        if [ "${IS_BUILDABLE}" == 'true' ]; then  
          docker-build
        else
          echo "WARN: This command (${app_op}) is not a valid operation for a non-buildable application!"
        fi
        ;;
    
    # Push the image for this application to the repository
    push)
        if [ "${IS_BUILDABLE}" == 'true' ]; then  
          docker-push
        else
          echo "WARN: This command (${app_op}) is not a valid operation for a non-buildable application!"
        fi
        ;;
    
    # Deploy this application to the cluster
    deploy)
        if [ "${IS_DEPLOYABLE}" == 'true' ]; then  
            
            k8s-run-app || echo "INFO: Trapped k8s-deploy-app: ${app_dir}"
            
            if [ "${HAS_PORT}" == 'true' ]; then
              k8s-expose-app || echo "INFO: Trapped k8s-expose-app: ${app_dir}"
            fi
            
            if [ "${HAS_APP_SCALING}" == 'true' ]; then
              k8s-autoscale-app || echo "INFO: Trapped k8s-expose-app: ${app_dir}"
            fi
        else
            echo "WARN: This command (${app_op}) is not a valid operation for a non-deployable application!"
        fi
        ;;

    # Add this application to the DNS
    add-dns)
        if [ "${IS_DEPLOYABLE}" != 'true' ]; then  
          echo "WARN: This command (${app_op}) is not a valid operation for a non-deployable application!"
        elif [ "${HAS_PORT}" != 'true' ]; then  
          echo "WARN: This command (${app_op}) is not a valid operation for an application with no port!"
        else
          awscli-add-elb-to-route53
        fi
        ;;
    
    # Run jmeter against the deployed app
    run-jmeter-www)
        if [ "${IS_DEPLOYABLE}" != 'true' ]; then  
          echo "WARN: This command (${app_op}) is not a valid operation for a non-deployable application!"
        elif [ "${HAS_PORT}" != 'true' ]; then  
          echo "WARN: This command (${app_op}) is not a valid operation for an application with no port!"
        else
          jmeter-run-www
        fi
        ;;
    
    # Run jmeter against the local app
    run-jmeter-local)
        if [ "${HAS_PORT}" == 'true' ]; then  
          jmeter-run-local
        else
          echo "WARN: This command (${app_op}) is not a valid operation for an application with no port!"
        fi
        ;;
    
    # Update the image for this application which when it is deployed on the cluster
    update)
        if [ "${IS_DEPLOYABLE}" == 'true' ]; then  
          k8s-update
        else
          echo "WARN: This command (${app_op}) is not a valid operation for a non-deployable application!"
        fi
        ;;
    
    # Describe the POD for this application
    describe-pod)
        if [ "${IS_DEPLOYABLE}" == 'true' ]; then  
          k8s-describe-pod
        else
          echo "WARN: This command (${app_op}) is not a valid operation for a non-deployable application!"
        fi
        ;;
    
    # Delete this application from the cluster idempotently.
    delete)
        if [ "${IS_DEPLOYABLE}" == 'true' ]; then
          k8s-delete-app-expose || echo "INFO: Trapped UNEXPOSED application: ${app_dir}"
          k8s-delete-app-autoscale || echo "INFO: Trapped UNSCALED application: ${app_dir}"
          k8s-delete-app || echo "INFO: Trapped UNDEPLOYED application: ${app_dir}"
        else
          echo "WARN: This command (${app_op}) is not a valid operation for a NON-DEPLOYABLE application!"
        fi
      ;;
    
    # A workspace to run debugging code.
    debug)
        add-elb-to-route53
      ;;
    *)
      echo "ERROR: This command (${app_op}) is not a valid operation!"
      exit 1
      ;;
esac

