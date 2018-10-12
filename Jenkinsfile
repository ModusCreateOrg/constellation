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
def get_captcha(Long hash_const) {
    Random rand = new Random()
    def op1 = rand.nextInt(MAX+1)
    def op2 = rand.nextInt(MAX+1) + MAX
    def op3 = rand.nextInt(MAX+1) 
    def captcha_problem = "CAPTCHA problem: What is the answer to this problem: ${op1} + ${op2} - ${op3}"
    Long captcha_answer = op1 + op2 - op3
    Long captcha_hash = captcha_answer ^ hash_const
    return [captcha_problem, captcha_hash.toString()]
}

def prepEnv = {
    sh ("""
        cp env.sh.sample env.sh
        rm -rf build
        mkdir build
    """)
}

def wrap = { fn->
    ansiColor('xterm') {
        fn()
    }
}

(captcha_problem, captcha_hash) = get_captcha(XOR_CONST)

/** Gather properties from user parameters */
properties([
    parameters([
        booleanParam(
            name: 'Build_Docker', 
            defaultValue: false, 
            description: 'Build docker machines on this build?'
        ),
        booleanParam(
            name: 'Apply_Terraform', 
            defaultValue: false, 
            description: 'Apply Terraform plan on this build?'
        ),
        booleanParam(
            name: 'Destroy_Terraform', 
            defaultValue: false, 
            description: 'Destroy Terraform resources?'
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
    ])
])

stage('Preflight') {
       
    // Check CAPTCHA
    def should_validate_captcha = params.Build_Docker || params.Apply_Terraform || params.Destroy_Terraform

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

