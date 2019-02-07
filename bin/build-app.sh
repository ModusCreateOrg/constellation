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
. "$DIR/config-k8s.sh"

# ARGS
app_name=${1:-}
op=${2:-build}

APP_DIR="$BASE_DIR/applications/${app_name}"
cd "${APP_DIR}" || echo "Can not find: ${APP_DIR}"
#echo "Building in: $(pwd)"
# shellcheck disable=SC1091
source ./config.sh

case "$op" in
     run)
       docker-run "${APP_ENV}" "${APP_NAM}" "${APP_VER}" "${APP_BASE}" 
       ;;   
     build)
       docker-build "${APP_ENV}" "${APP_NAM}" "${APP_VER}"
       ;;
     shell)
       docker-shell "${APP_ENV}" "${APP_NAM}" "${APP_VER}" "${APP_BASE}" 
       ;;
     push)
       docker-push "${APP_ENV}" "${APP_NAM}" "${APP_VER}"
       ;;
     deploy)
       k8s-deploy "${APP_ENV}" "${APP_NAM}" "${APP_VER}"
       ;;
     update)
       k8s-update "${APP_ENV}" "${APP_NAM}" "${APP_VER}"
       ;;
     delete)
       k8s-delete "${APP_ENV}" "${APP_NAM}" "${APP_VER}"
       ;;
     image-name)
        image-name "${APP_ENV}" "${APP_NAM}" "${APP_VER}" 
        echo "${IMAGE_NAME}"
       ;;
     pod-name)
        pod-name "${APP_ENV}" "${APP_NAM}"
        echo "${POD_NAME}"
       ;;
     version)
        echo "${APP_VER}"
       ;;
 esac




