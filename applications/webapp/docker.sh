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
BASE_DIR="$DIR/../.."

# shellcheck disable=SC1090
. "$BASE_DIR/bin/common-docker.sh"
# shellcheck disable=SC1090
. "$DIR/bin/config.sh"

op=${1:-build}

case "$op" in
     run)
       docker-run "${APP_BASE}" "${APP_ENV}" "${APP_NAM}" "${APP_VER}"
       ;;   
     build)
       docker-build "${DIR}" "${APP_ENV}" "${APP_NAM}" "${APP_VER}"
       ;;
     shell)
       docker-shell "${APP_BASE}" "${APP_ENV}" "${APP_NAM}" "${APP_VER}"
       ;;
 esac




