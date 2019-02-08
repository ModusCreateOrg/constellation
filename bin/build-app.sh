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
. "$DIR/common-docker.sh"
# shellcheck disable=SC1090
. "$DIR/common-k8s.sh"
# shellcheck disable=SC1090
. "$BASE_DIR/env.sh"
# shellcheck disable=SC1090
. "$BASE_DIR/config/k8s.sh"

# ARGS
dir_name=${1:-}
op=${2:-build}

APP_DIR="$BASE_DIR/applications/${dir_name}"
cd "${APP_DIR}" || echo "Can not find: ${APP_DIR}"
echo "Building in: $(pwd)"
# shellcheck disable=SC1091
source ./config-app.sh

  case "$op" in
    run)
      docker-run
      ;;   
    build)
      docker-build
      ;;
    shell)
      docker-shell
      ;;
    push)
      docker-push
      ;;
    deploy)
        if [ "$IS_DEPLOYABLE" == 'true' ]; then  
          k8s-deploy
        else
          echo "This command (${op}) is not a valid operation for an image-only application!"
          exit 1
        fi
        ;;
    update)
        if [ "$IS_DEPLOYABLE" == 'true' ]; then  
          k8s-update
        else
          echo "This command (${op}) is not a valid operation for an image-only application!"
          exit 1
        fi
        ;;
    delete)
        if [ "$IS_DEPLOYABLE" == 'true' ]; then  
          k8s-delete
        else
          echo "This command (${op}) is not a valid operation for an image-only application!"
          exit 1
        fi
      ;;
    *)
      echo "This command (${op}) is not a valid operation!"
      exit 1
      ;;
esac

