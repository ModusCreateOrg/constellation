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

export ALB_NAME="k83-demo-alb"
export VPC_NAME="${PROJECT_NAME}-vpc"

###
#Note: the lowercase vars are not exported and intended to be use as local variables in this file.
#      Doing so would cause the guards to work incorrectly with iteration.
###


function get-vpc-id(){
	if [ -z ${VPC_ID+x} ]; then
		# Find the VPC ID from the name
		vpc_id_query=".Vpcs[] | select( any (.Tags[]; .Value == \"k8s-eks-scaling-demo-vpc\")) | .VpcId"
		VPC_ID="$( aws ec2  describe-vpcs \
			| jq "${vpc_id_query}" \
		 	|sed 's/"//g'  \
		)"
		export VPC_ID #The EXPORT is ok here since there is only one value per project.
		echo "The VPC ID is ${VPC_ID}"
	fi
}

function get-the-target-group-name(){
	the_target_group_name="${IMAGE_NAME}-alb-target-group"
	echo "The ALB target group name is ${the_target_group_name}"

}

function get-the-elb-name(){
	if [ -z ${the_elb_name+x} ]; then
		# Get an argiment list of all the ELB names
		elb_names="$(aws elb describe-load-balancers \
			| grep "LoadBalancerName" \
			| sed 's/.* "//' \
			| tr ',"\n' ' ' \
			)"

		# Find this elb name from the tags
		elb_name_query=".TagDescriptions[] | select( any (.Tags[]; .Key == \"kubernetes.io/service-name\" and .Value == \"default/${IMAGE_NAME}\")) | .LoadBalancerName"
		# shellcheck disable=SC2086
		the_elb_name="$(aws elb describe-tags --load-balancer-names ${elb_names} \
		 	| jq "${elb_name_query}" \
		 	|sed 's/"//g'  \
		 	)"
		 echo "The ELB name is |${the_elb_name}|"
	fi
}

function get-the-elb-dns-name(){
	if [ -z ${the_elb_dns_name+x} ]; then
		get-the-elb-name

		# Find this elb dns name
		elb_dns_name_query=".LoadBalancerDescriptions[] | select( .LoadBalancerName == \"${the_elb_name}\") | .DNSName"
		# shellcheck disable=SC2086
		the_elb_dns_name="$(aws elb describe-load-balancers --load-balancer-names ${elb_names} \
		 	| jq "${elb_dns_name_query}" \
		 	|sed 's/"//g'  \
		 	)"
		 echo "The ELB DNS name is |${the_elb_dns_name}|"
	fi
}

function add-elb-to-route53(){
	get-the-elb-dns-name

	json_file="$(mktemp)"
	tee "${json_file}" <<- EOF
	{
	    "Comment": "Adding an CNAME record for an EKS ELB to the DNS",
	    "Changes": [
	      {
	        "Action": "UPSERT",
	        "ResourceRecordSet": {
	          "Name": "${APP_DOMAIN_NAME}",
	          "Type": "CNAME",
	          "TTL": 300,
	          "ResourceRecords": [
	            {
	              "Value": "${the_elb_dns_name}"
	            }
	          ]
	        }
	      }
	    ]
	}
	EOF

	 echo "The recordset file is: ${json_file}"

	 aws route53 change-resource-record-sets \
          --hosted-zone-id "${APP_HOSTED_ZONE_ID}" \
          --change-batch "file://${json_file}"

}

# Not used now, but remains as a sample
function get-the-elb-ip(){
	if [ -z ${the_elb_ip+x} ]; then
		get-the-elb-name
		# Find the elb ip address from the name.
		elb_ip_query=".NetworkInterfaces[] | select( .Description == \"ELB ${the_elb_name}\") | .PrivateIpAddresses[0] | .PrivateIpAddress"

		the_elb_ip="$(aws ec2 describe-network-interfaces \
			| jq "${elb_ip_query}" \
		 	| tr '"' ' ' \
		 	| head -1 \
		 	| tr '\n' ' ' \
		 	| sed 's/ //g' \
		 	)"
		 echo "The ELB IP is |${the_elb_ip}|"
	fi
}

# Not used now, but remains as a sample
function create-target-group(){
	get-the-elb-ip
	get-the-target-group-name
	get-vpc-id

    target_group_response="$(aws elbv2 create-target-group \
          --name "${the_target_group_name}" \
          --protocol HTTP \
          --port 80 \
          --vpc-id "${VPC_ID}" \
          --target-type ip \
          )" 
          #[--health-check-protocol <value>]
          #[--health-check-port <value>]
          #[--health-check-enabled | --no-health-check-enabled]
          #[--health-check-path <value>]
          #[--health-check-interval-seconds <value>]
      	  #[--health-check-timeout-seconds <value>]
          #[--healthy-threshold-count <value>]
          #[--unhealthy-threshold-count <value>]
          #[--matcher <value>]
          #[--target-type <value>]
          #[--cli-input-json <value>]
          #[--generate-cli-skeleton <value>]

    #echo "${target_group_response}"
		
    the_target_group_arn="$( grep TargetGroupArn <<< "${target_group_response}" \
	   	| sed 's/.* "//' \
	   	| tr ',"\n' ' ' \
	   	| sed 's/ //g' \
    )"
    echo "The target group ARN is |${the_target_group_arn}|"

	aws elbv2 register-targets \
          --target-group-arn "${the_target_group_arn}" \
          --targets "Id=${the_elb_ip}"

}
