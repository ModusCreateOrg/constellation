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

# shellcheck disable=SC1090
. "$DIR/common.sh"

cd "$BASE_DIR"
clean_root_owned_docker_files
git clean -fdx
cp env.sh.sample env.sh
cp terraform/variables-local.tf.sample terraform/variables-local.tf
rm -rf build
mkdir -p build

if [[ ! -x /usr/local/bin/aws-iam-authenticator ]]; then
    echo "Installing: aws-iam-authenticator"
    curl -o /usr/local/bin/aws-iam-authenticator https://amazon-eks.s3-us-west-2.amazonaws.com/1.11.5/2018-12-06/bin/linux/amd64/aws-iam-authenticator \
    chmod 755 /usr/local/bin/aws-iam-authenticator
else
    echo "Found: aws-iam-authenticator"
fi
if [[ ! -x /usr/local/bin/kubectl ]]; then
    echo "Installing: kubectl"
    curl -o /usr/local/bin/kubectl https://amazon-eks.s3-us-west-2.amazonaws.com/1.11.5/2018-12-06/bin/linux/amd64/kubectl
    chmod 755 /usr/local/bin/kubectl
else
    echo "Found: kubectl"
fi

