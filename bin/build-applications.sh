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

#shellcheck disable=SC1090
. "$BASE_DIR/env.sh"

cd "$BASE_DIR"

# shellcheck disable=SC1090
./applications/spin/build.sh
# shellcheck disable=SC1090
./applications/webapp/build.sh

echo "####### K8S DOCKER IMAGES #######"
docker image ls | grep k8s || echo "-- NONE --"
echo "####### K8S DOCKER CONTAINERS #######"
docker container ls | grep k8s || echo "-- NONE --"
