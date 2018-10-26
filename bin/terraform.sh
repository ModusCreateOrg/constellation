#!/usr/bin/env bash
#
# terraform.sh
#
# Wrapper script for running Terraform through Docker
#
# Useful when running in Jenkins CI or other contexts where you have Docker
# available.

# Set bash unofficial strict mode http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail
#IFS=$'\n\t'

# Set DEBUG to true for enhanced debugging: run prefixed with "DEBUG=true"
${DEBUG:-false} && set -vx
# Credit to https://stackoverflow.com/a/17805088
# and http://wiki.bash-hackers.org/scripting/debuggingtips
export PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'

# Credit to http://stackoverflow.com/a/246128/424301
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BASE_DIR="$DIR/.."
BUILD_DIR="$BASE_DIR/build"
export BUILD_DIR
#shellcheck disable=SC1090
. "$DIR/common.sh"
#shellcheck disable=SC1090
. "$BASE_DIR/env.sh"
#shellcheck disable=SC1090
. "$DIR/common-terraform.sh"

DOCKER_TERRAFORM=$(get_docker_terraform)
DOCKER_LANDSCAPE=$(get_docker_landscape)

verb=${1:?You must specify a verb: plan, plan-destroy, apply}

# http://redsymbol.net/articles/bash-exit-traps/
trap clean_root_owned_docker_files EXIT


function plan() {
    local extra
    local output
    local retcode
    local targets
    extra=${1:-}
    output="$(mktemp)"
    targets=$(get_targets)

    set +e
    #shellcheck disable=SC2086
    $DOCKER_TERRAFORM plan \
        $extra \
        $targets \
        -lock=true \
        -input="$INPUT_ENABLED" \
        -var project_name="$PROJECT_NAME" \
        -var-file="/app/build/extra.tfvars" \
        -out="$TF_PLAN" \
        "$TF_DIR" \
        > "$output"
    retcode="$?"
    set -e
    if [[ "$retcode" = 0 ]]; then
        $DOCKER_LANDSCAPE - < "$output"
    else
        cat "$output"
    fi
    rm -f "$output"
    return "$retcode"
}

function plan-destroy() {
   cat <<EOF

*******************************************************
************                             **************
************  -----=== WARNING ===------ **************
************  Planning Terraform Destroy ************** 
************                             ************** 
*******************************************************

EOF
    plan "-destroy"
}

function apply() {
    $DOCKER_TERRAFORM apply \
        -lock=true \
        "$TF_PLAN"
    $DOCKER_TERRAFORM output 
}

function output() {
}

case "$verb" in
plan)
  Message="Executing terraform plan."
  ;;
plan-destroy)
  Message="Executing terraform plan, with destroy."
  ;;
apply)
  Message="Executing terraform apply."
  ;;
*)
  echo 'Unrecognized verb "'"$verb"'" specified. Use plan, plan-destroy, or apply'
  exit 1
  ;;
esac

echo "$Message"
init_terraform
"$verb"

