#!/usr/bin/env bash
# common-terraform.sh
#
# Functions and variables related to Terraform


TF_VERSION=0.11.11
# TF_DIR is from the perspective of the Terraform docker container
TF_DIR="/app/terraform"

TF_PLAN="$TF_DIR/tf.plan"
ENV_FILE=$(get_env_tmpfile)

function get_var_tmpfile() {
# Emit a Terraform variables tempfile
    local TMPFILE
    local EXTRA=${1:-# no extras}
    mkdir -p "$BUILD_DIR"
    TMPFILE="$BUILD_DIR/extra.tfvars"
    echo "$EXTRA" > "$TMPFILE"
    echo "$TMPFILE"
}

VAR_FILE="$(get_var_tmpfile "${Extra_Variables:-}")"
export VAR_FILE ENV_FILE TF_PLAN TF_VERSION

function get_targets() {
    for target in ${Terraform_Targets:-}; do
        echo -n "-target=$target "
    done
}

function get_docker_landscape() {
    echo "docker run -i --rm alpine/landscape"
}

function get_docker_terraform {
    echo "docker run -i --rm
        ${USE_TTY}
        --env-file $ENV_FILE
        --mount type=bind,source=${BASE_DIR}/terraform,target=${TF_DIR}
        --mount type=bind,source=${BASE_DIR}/bin,target=/app/bin
        --mount type=bind,source=${BASE_DIR}/applications,target=/app/applications
        --mount type=bind,source=${BUILD_DIR},target=/app/build
        --mount type=bind,source=${HOME}/.aws,target=/root/.aws
        --mount type=bind,source=${HOME}/.ssh,target=/root/.ssh
        -w ${TF_DIR}
        hashicorp/terraform:${TF_VERSION}"
}

function init_terraform() {
    #shellcheck disable=SC2086,SC2046
    $DOCKER_TERRAFORM init \
        -input="$INPUT_ENABLED" \
        -backend-config bucket=tf-state.${PROJECT_NAME}.${AWS_DEFAULT_REGION}.$(get_aws_account_id) \
        -backend-config dynamodb_table=TerraformStatelock-${PROJECT_NAME} \
        -backend-config region=${AWS_DEFAULT_REGION} \
        -backend-config encrypt=true
    # Generate an SSH keypair if none exists yet
    if [[ ! -f ~/.ssh/id_rsa.pub ]]; then
        #shellcheck disable=SC2174
        mkdir -p -m 0700 ~/.ssh
        ssh-keygen -t rsa -b 2048 -P '' -f ~/.ssh/id_rsa
    fi
    if [[ ! -x /usr/local/bin/aws-iam-authenticator ]]; then
        echo "Installing: aws-iam-authenticator"
        curl -o /usr/local/bin/aws-iam-authenticator https://amazon-eks.s3-us-west-2.amazonaws.com/1.11.5/2018-12-06/bin/linux/amd64/aws-iam-authenticator
        chmod 755 /usr/local/bin/aws-iam-authenticator
    fi
    if [[ ! -x /usr/local/bin/kubectl ]]; then
        echo "Installing: kubectl"
        curl -o /usr/local/bin/kubectl https://amazon-eks.s3-us-west-2.amazonaws.com/1.11.5/2018-12-06/bin/linux/amd64/kubectl
        chmod 755 /usr/local/bin/kubectl
    fi
}
