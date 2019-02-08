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

# ARGS
dir_name=${1:-all}
op=${2:-build}

if [ "${dir_name}" = "all" ]; then
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
	# shellcheck disable=SC1090
	. "${DIR}/build-app.sh" "${dir_name}" "${op}"
fi