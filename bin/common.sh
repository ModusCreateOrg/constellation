#!/usr/bin/env bash
# common.sh

# Only use TTY for Docker if we detect one, otherwise
# this will balk when run in Jenkins
# Thanks https://stackoverflow.com/a/48230089
declare USE_TTY
test -t 1 && USE_TTY="-t" || USE_TTY=""

declare INPUT_ENABLED
test -t 1 && INPUT_ENABLED="true" || INPUT_ENABLED="false"

export INPUT_ENABLED USE_TTY

# https://gist.github.com/samkeen/4255e1c8620be643d692
# Thanks to GitHub user samkeen
function is_ec2() {
    set +e
    INTERFACE=$(curl --silent http://169.254.169.254/latest/meta-data/network/interfaces/macs/  --connect-timeout 1)
    set -e
    if [[ -n "$INTERFACE" ]]; then  # we are running on EC2
        return 0
    fi
    return 1
}

function get_env_tmpfile() {
# Clean up the env file for use in terraform
    local TMPFILE
    TMPFILE="$(mktemp)"
    grep ^export "$DIR/../env.sh" | cut -c8- > "$TMPFILE"
    echo "$TMPFILE"
}

function get_aws_account_id() {
    aws sts get-caller-identity \
        --query Arn \
        --output text \
        | cut -d: -f5
}

function clean_root_owned_docker_files {
    # Fix file permissions on Jenkins / Linux as
    # Docker makes a bunch of root-owned files as it works
    local TF_DIR=/app
    local BASE_DIR
    BASE_DIR="$(pwd)"
    if is_ec2; then
        docker run -i \
            --mount type=bind,source="${BASE_DIR}"/terraform,target="${TF_DIR}" \
            -w "${TF_DIR}" \
            --entrypoint /bin/sh \
            busybox \
            <<< "chown -R $(id -u):$(id -g) ${TF_DIR}"
    fi
}

function get_docker_landscape() {
    echo "docker run -i --rm alpine/landscape"
}

function get_docker_shellcheck() {
    # See https://hub.docker.com/r/nlknguyen/alpine-shellcheck/
    # and https://github.com/koalaman/shellcheck/issues/727
    echo "docker run --rm -i ${USE_TTY} -v $(pwd):/mnt koalaman/shellcheck"
}

