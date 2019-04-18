#!/usr/bin/env bash

function print-help() {

cat << EOF
===============================
USAGE: 

build.sh                        
    Builds all of the applications. ( build.sh build all )

build.sh help                       
    Prints this help message.

build.sh <proj-cmd>                     
    
build.sh <app-cmd>          
    Executes <app-cmd> for all of the applications.

build.sh <app-cmd> [all|<app-dir> [<app-dir ... ]]
    Executes <app-cmd> in the context of the application directory <app-dir>.

WHERE:

    <proj-cmd>:

        'help'              - Prints this help message.

        'stand-up-demo'     - Standup all of the infrastrucrure for the demo

        'tear-down-demo'    - Tear down all of the infrastrucrure for the demo

        'list-pods'         - Lists all of the pods.

        'list-svcs'         - Lists all of the services.

        'kubeconfig'        - Update the kubeconfig in your home dir.

        'create-dashboard'  - Create the cluster dashboard and the admin user. The token prints on stdout.

        'proxy-dashboard'   - Open a proxy to the dashboard.

        'install-metrics-server' - Install the metrics server on the cluster.
         
        'enable-cluster-autoscaling' - Configure and enable autoscaling for the cluster.


    <app-dir>:
    
        Specifies the application directory of the selected app.
        A value of 'all' iterates over the application directories.
        Directories that begin with '_' are skipped in the iteration.


    <app-cmd>:

        'run'               
            - Run this application locally exposing a port if appropriate.

        'build'             
            - Build the image for this application.

        'shell'             
            - Run this application locally and open a shell. It exposes the port if appropriate.

        'push'              
            - Push the image for this application to the repository.

        'deploy'            
            - Deploy this application to the cluster.

        'run-jmeter-local'  
            - Run jmeter against the local app instance.

        'run-jmeter-www'    
            - Run jmeter against the deployed app instance.

        'add-dns'           
            - Add this application to the DNS.

        'update'            
            - Update the image for this application which when it is deployed on the cluster.

        'list-pods'         
            - List all of the PODs in the cluster.

        'describe-pod'      
            - Describe the POD for this application.

        'delete'            
            - Delete this application from the cluster idempotently.
            
EOF

}