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


function awscli-get-vpc-id(){
	if [ -z ${VPC_ID+x} ]; then
		# Find the VPC ID from the name
		vpc_id_query=".Vpcs[] | select( any (.Tags[]; .Value == \"k8s-eks-scaling-demo-vpc\")) | .VpcId"
		VPC_ID="$( aws ec2  describe-vpcs \
			| jq "${vpc_id_query}" \
		 	|sed 's/"//g'  \
		)"
		export VPC_ID
		echo "The VPC ID is ${VPC_ID}"
	fi
}

function awscli-get-elb-name(){
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
}

function awscli-get-elb-dns-name(){
	awscli-get-elb-name

	# Find this elb dns name
	elb_dns_name_query=".LoadBalancerDescriptions[] | select( .LoadBalancerName == \"${the_elb_name}\") | .DNSName"
	# shellcheck disable=SC2086
	the_elb_dns_name="$(aws elb describe-load-balancers --load-balancer-names ${elb_names} \
	 	| jq "${elb_dns_name_query}" \
	 	|sed 's/"//g'  \
	 	)"
	 echo "The ELB DNS name is |${the_elb_dns_name}|"
}

function awscli-add-elb-to-route53(){

	if [ "${HAS_DNS:-false}" != 'true' ]; then
		echo "Can not add a CNAME entry to Route53 when the application has no DNS: ${APPLICATION_NAME}"
		exit 1
	fi
	awscli-get-elb-dns-name

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
