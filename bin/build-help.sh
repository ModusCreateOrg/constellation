#!/usr/bin/env bash

function print-help() {

cat << EOF
===============================
USAGE: 

build.sh                       - Builds all of the applications ( build.sh all build )
build.sh print-help.           - Prints this help message.
build.sh <app-dir> <command>   - Executes <command> in the context of the application directory <app-dir>.

WHERE:

<app-dir> - Specifies the application directory that contains the application to build. 
            A value of 'all' iterates over all the application directories.
            Any directory that begins with a '_' will be skipped in the iteration.

COMMANDS:

'run'      - Run this application locally exposing a port if appropriate.

'build'    - Build the image for this application.

'shell'    - Run this application locally and open a shell. It exposes the port if appropriate.

'push'     - Push the image for this application to the repository.

'deploy'   - Deploy this application to the cluster.

'add-dns' 	- Add this application to the DNS.

'update'   - Update the image for this application which when it is deployed on the cluster.

'list'     - List all of the PODs in the cluster.

'describe' - Describe the POD for this application.

'delete'   - Delete this application from the cluster.

EOF

}