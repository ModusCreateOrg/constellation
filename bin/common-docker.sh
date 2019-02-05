#!/usr/bin/env bash
# common-docker.sh

# Only use TTY for Docker if we detect one, otherwise
# this will balk when run in Jenkins
# Thanks https://stackoverflow.com/a/48230089
declare USE_TTY
test -t 1 && USE_TTY="-t" || USE_TTY=""

declare INPUT_ENABLED
test -t 1 && INPUT_ENABLED="true" || INPUT_ENABLED="false"

export INPUT_ENABLED USE_TTY

function docker-build(){
	dir=$1; env=$2;	app=$3; ver=$4
	OCWD=$(pwd)
	cd "${dir}" || exit 1
	docker build -t "k8s/${env}/${app}:${ver}" .
	cd "${OCWD}" || exit 1
}

function docker-run(){
	base=$1; env=$2; app=$3; ver=$4

	echo Running container: "k8s/${env}/${app}:${ver}"
	echo "   local:${base}080 '-->' container:80"
	docker run \
		-p "${base}080:80" \
		-it "k8s/${env}/${app}:${ver}"
}

function docker-shell(){
	base=$1; env=$2; app=$3; ver=$4

	echo Running container: "k8s/${env}/${app}:${ver}"
	echo "   local:${base}080 '-->' container:80"
	docker run \
		-p "${base}080:80" \
		-it "k8s/${env}/${app}:${ver}" \
		/usr/bin/bash
}

