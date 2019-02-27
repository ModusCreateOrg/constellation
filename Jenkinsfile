#!/usr/bin/env groovy
/*
 * Jenkinsfile
 *
 * Use the Scripted style of Jenkinsfile in order to
 * write more Groovy functions and use variables to
 * control the workflow.
 */ 

import java.util.Random

// Set default variables
final default_timeout_minutes = 20

/** Set up CAPTCHA*/
final int MAX = 10
final Long XOR_CONST = MAX * 3

def get_captcha(Long hash_const, int max) {
    Random rand = new Random()
    def op1 = rand.nextInt(max+1)
    def op2 = rand.nextInt(max+1) + max
    def op3 = rand.nextInt(max+1) 
    def captcha_problem = "CAPTCHA problem: What is the answer to this problem: ${op1} + ${op2} - ${op3}"
    Long captcha_answer = op1 + op2 - op3
    Long captcha_hash = captcha_answer ^ hash_const
    return [captcha_problem, captcha_hash.toString()]
}

def prepEnv = {
    sh ("""
        cp env.sh.sample env.sh
        cp terraform/variables-local.tf.sample terraform/variables-local.tf
        rm -rf build
        mkdir build
    """)
}

def wrap = { fn->
    ansiColor('xterm') {
        fn()
    }
}

(captcha_problem, captcha_hash) = get_captcha(XOR_CONST,MAX)

/** Gather properties from user parameters */
properties([
    parameters([
        booleanParam(
            name: 'Destroy_Terraform', 
            defaultValue: false, 
            description: 'Destroy Terraform resources?'
        ),
        booleanParam(
            name: 'Apply_Terraform', 
            defaultValue: false, 
            description: 'Apply Terraform plan?'
        ),
        string(
            name: 'Application', 
            defaultValue: 'all', 
            description: '''The application to build. 
                            Separate multiple values by a space.
                            The value 'all' iterates over the applications.'''
        ),
        booleanParam(
            name: 'Build_Container', 
            defaultValue: false, 
            description: 'Build container/s?'
        ),
        booleanParam(
            name: 'Push_Container', 
            defaultValue: false, 
            description: 'Push container/s to the repository?'
        ),
        booleanParam(
            name: 'Deploy_Container', 
            defaultValue: false, 
            description: 'Deploy container/s?'
        ),
        booleanParam(
            name: 'Add_To_DNS', 
            defaultValue: false, 
            description: 'Add the application ELB to DNS?'
        ),
        booleanParam(
            name: 'Update_Container', 
            defaultValue: false, 
            description: 'Update container/s on this build?'
        ),
        booleanParam(
            name: 'Run_Jmeter', 
            defaultValue: false, 
            description: 'Run jmeter against the deployed app?'
        ),
        booleanParam(
            name: 'Delete_Container', 
            defaultValue: false, 
            description: 'Delete container/s?'
        ),
        string(
            name: 'CAPTCHA_Guess', 
            defaultValue: '', 
            description: captcha_problem
        ),
        string(
            name: 'CAPTCHA_Hash',
            defaultValue: captcha_hash,
            description: 'Hash for CAPTCHA answer (DO NOT modify)'
        ),
        string(
            name: 'Terraform_Targets',
            defaultValue: '',
            description: '''Specific Terraform resource or resource names to target
                            (Use this to modify or delete less than the full set of resources'''
        ),
        text(
            name: 'Extra_Variables', 
            defaultValue: '', 
            description: '''Terraform Variables to define for this run. 
                            Allows you to override declared variables.
                            Put one variable per line, in JSON or HCL like this:
                            associate_public_ip_address = "true"'''
        ),
        string(
            name: 'Build_Command_Arguments', 
            defaultValue: '', 
            description: 'The arguments to the build command.'
        ),
        booleanParam(
            name: 'Run_Build_Command', 
            defaultValue: false, 
            description: 'Run build.sh with the above arguments for debugging.'
        )
    ])
])

stage('Preflight') {
       
    // Check CAPTCHA
    def should_validate_captcha = false
    
    /*
    def should_validate_captcha =  params.Build_Container || params.Push_Container || params.Deploy_Container || params.Updatey_Container || params.Delete_Container || params.Apply_Terraform || params.Destroy_Terraform || params.Add_To_DNS
    */
    
    if (should_validate_captcha) {
        if (params.CAPTCHA_Guess == null || params.CAPTCHA_Guess == "") {
            throw new Exception("No CAPTCHA guess detected, try again!")
        }
        def guess = params.CAPTCHA_Guess as Long
        def hash = params.CAPTCHA_Hash as Long
        if ((guess ^ XOR_CONST) != hash) {
            throw new Exception("CAPTCHA incorrect, try again")
        }
        echo "CAPTCHA validated OK"
    } else {
        echo "No CAPTCHA required, continuing"
    }
}

stage('Checkout') {
    node {
        timeout(time:default_timeout_minutes, unit:'MINUTES') {
            checkout scm
            sh ('bin/prep.sh') // Clean and prepare environment
            stash includes: "**", excludes: ".git/", name: 'src'
        }
    }
}

stage('Validate') {
    node {
        unstash 'src'
        wrap.call({
            // Validate packer templates, check branch
            sh ("./bin/validate.sh")
        })
    }
}

def terraform_prompt = 'Should we apply the Terraform plan?'


stage('Plan Terraform') {
    node {
        unstash 'src'
        wrap.call({
            prepEnv()
            def verb = "plan"
            if (params.Destroy_Terraform) {
                verb += '-destroy';
                terraform_prompt += ' WARNING: will DESTROY resources';
            }
            sh ("""
                ./bin/terraform.sh ${verb}
                """)
        })
        stash includes: "**", excludes: ".git/", name: 'plan'
    }
}

if (params.Apply_Terraform || params.Destroy_Terraform) {
    // See https://support.cloudbees.com/hc/en-us/articles/226554067-Pipeline-How-to-add-an-input-step-with-timeout-that-continues-if-timeout-is-reached-using-a-default-value
    def userInput = false
    try {
        timeout(time: default_timeout_minutes, unit: 'MINUTES') {
            userInput = input(message: terraform_prompt)
        }
        stage('Apply Terraform') {
            node {
                unstash 'plan'
                wrap.call({
                    prepEnv()
                    sh ("./bin/terraform.sh apply")
                })
            }
        }
    } catch(err) { // timeout reached or other error
        echo err.toString()
        currentBuild.result = 'ABORTED'
    }
}

if (params.Build_Container) {
    stage('Build Application Containers'){
        node {
            timeout(time:default_timeout_minutes, unit:'MINUTES') {
                sh ("./bin/build.sh build ${params.Application}")
            }   
        }
    }
}

if (params.Push_Container) {
    stage('Push Application Containers'){
        node {
            timeout(time:default_timeout_minutes, unit:'MINUTES') {
                sh ("./bin/build.sh push ${params.Application}")
            }   
        }
    }
}

if (params.Deploy_Container) {
    stage('Deploy Application Containers'){
        node {
            timeout(time:default_timeout_minutes, unit:'MINUTES') {
                sh ("./bin/build.sh deploy ${params.Application}")
                sh ("./bin/build.sh describe-pod" ${params.Application} )
            }   
        }
    }
}

if (params.Add_To_DNS) {

    stage('ADD Application to DNS'){
        node {
            if (params.Deploy_Container) {
                sh ("sleep 20")
            }
            timeout(time:default_timeout_minutes, unit:'MINUTES') {
                sh ("./bin/build.sh add-dns ${params.Application}")
            }   
        }
    }
}

if (params.Update_Container) {
    stage('Update Application Containers'){
        node {
            timeout(time:default_timeout_minutes, unit:'MINUTES') {
                sh ("./bin/build.sh update"  ${params.Application})
                sh ("./bin/build.sh describe-pod ${params.Application}")
            }   
        }
    }
}

if (params.Run_Jmeter) {

    stage('Run Jmeter'){
        node {
            if (params.Deploy_Container || params.Update_Container) {
                sh ("sleep 20")
            }
            timeout(time:default_timeout_minutes, unit:'MINUTES') {
                sh ("./bin/build.sh run-jmeter-www ${params.Application}")
            }   
        }
    }
}

if (params.Delete_Container) {
    stage('Delete Application Containers'){
        node {
            timeout(time:default_timeout_minutes, unit:'MINUTES') {
                sh ("./bin/build.sh delete" ${params.Application})
                sh ("./bin/build.sh list-pods ${params.Application}")
            }   
        }
    }
}
if (params.Run_Build_Command) {
    stage('Run Build Command'){
        node {
            timeout(time:default_timeout_minutes, unit:'MINUTES') {
                sh ("./bin/build.sh ${Build_Command_Arguments}")
            }   
        }
    }
}


