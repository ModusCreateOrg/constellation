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

#
APP_JMETER_DIR="${APP_DIR}/jmeter"
export APP_JMETER_DIR

#
APP_JMETER_BUILD_DIR="${APP_BUILD_DIR}/jmeter"
export APP_JMETER_BUILD_DIR
mkdir -p "${APP_JMETER_BUILD_DIR}"

function jmeter-run-www(){
	#rm -rf "${APP_JMETER_BUILD_DIR}/www-report"
	docker run -t -v "${APP_DIR}:/app" justb4/jmeter -n \
	   -t /app/jmeter/www.jmx \
	   -l /app/build/jmeter/www.jtl \
	   -j /app/build/jmeter/www.log \
	   -o /app/build/jmeter/www-report \
	   "$@"
}

function jmeter-run-local(){
	#rm -rf "${APP_JMETER_BUILD_DIR}/local-report"
	jmeter -n \
	   -t "${APP_JMETER_DIR}/local.jmx" \
	   -l "${APP_JMETER_BUILD_DIR}/local.jtl" \
	   -j "${APP_JMETER_BUILD_DIR}/www.log" \
	   -o "${APP_JMETER_BUILD_DIR}/www-report" \
	   "$@"
}
