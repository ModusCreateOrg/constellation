#!/usr/bin/env bash

function print-help() {

cat << EOF
===============================
USAGE: 

build.sh                       - Builds all of the applications ( build.sh all build )
build.sh print-help.           - Prints this help message.
build.sh <app-dir> <command>   - Executes <command> in the context of the application directory <app-dir>.

WHERE:

<app-dir> - Specifies the application directory of the app to build.
            Separate multiple values with a space. 
            A value of 'all' iterates over the application directories.

COMMANDS:

'run'               - Run this application locally exposing a port if appropriate.

'build'             - Build the image for this application.

'shell'             - Run this application locally and open a shell. It exposes the port if appropriate.

'push'              - Push the image for this application to the repository.

'deploy'            - Deploy this application to the cluster.

'run-jmeter-local'  - Run jmeter against the local app instance.

'run-jmeter-www'    - Run jmeter against the deployed app instance.

'add-dns' 	        - Add this application to the DNS.

'update'            - Update the image for this application which when it is deployed on the cluster.

'list-pods'         - List all of the PODs in the cluster.

'describe-pod'      - Describe the POD for this application.

'delete'            - Delete this application from the cluster.

'idempotent-delete' - Delete this application from the cluster without failing if the application is not deployed.
 
EOF

}