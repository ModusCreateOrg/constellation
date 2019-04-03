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


function helm-get-helm-dir(){
	dir="${BASE_DIR}/helm"
	mkdir -p "${dir}"
	echo "${dir}"
}

function helm-cli(){
	k8s-update-kubeconfig
	# shellcheck disable=SC2068
	helm --kubeconfig "$(k8s-get-kubeconfig-dir)/config" $@
}

function helm-apply-iam-autoscaling-policy(){

	json_file="$(mktemp)"
	tee "${json_file}" <<- EOF
	{
	    "Version": "2012-10-17",
	    "Statement": [
	        {
	            "Effect": "Allow",
	            "Action": [
	                "autoscaling:DescribeAutoScalingGroups",
	                "autoscaling:DescribeAutoScalingInstances",
	                "autoscaling:DescribeTags",
	                "autoscaling:SetDesiredCapacity",
	                "autoscaling:TerminateInstanceInAutoScalingGroup"
	            ],
	            "Resource": "*"
	        }
	    ]
	}
	EOF
	awscli-add-cloudformation-iam-policy "${json_file}"
	rm -f "${json_file}"

}

function helm-set-asg-tags(){
	# Set the ASG tags for cluster auto scaling.
	echo "INFO: helm-enable-cluster-autoscaling"
	awscli-rmv-asg-tag "k8s.io/cluster-autoscaler/disabled" "true"
	awscli-set-asg-tag "k8s.io/cluster-autoscaler/enabled" "true"
	awscli-set-asg-tag "k8s.io/cluster-autoscaler/${CLUSTER_NAME}"
}

function helm-init(){
    # Initialize helm
    rm -rf "$(helm-get-helm-dir)"
	cd "$(helm-get-helm-dir)" || exit 1
	helm-cli  --home "$(helm-get-helm-dir)" init --history-max 200
	helm-cli repo update
}

function helm-get-cluster-autoscaler(){
  	# Download the cluster-autoscaler
	helm-cli fetch stable/cluster-autoscaler
	tar -zxf cluster-autoscaler-*.tgz

	# Set the auto-scaler configurations
	mv cluster-autoscaler/values.yaml cluster-autoscaler/values.yaml.orig
	ssl_cert_path="/etc/kubernetes/pki/ca.crt"
	  sed "s|awsRegion: .*|awsRegion: ${AWS_DEFAULT_REGION}|" cluster-autoscaler/values.yaml.orig \
	  | sed "s|clusterName: .*|clusterName: ${CLUSTER_NAME}|" \
	  | sed "s|create: false.*|create: true|" \
	  | sed "s|sslCertPath: .*|sslCertPath: ${ssl_cert_path}|" > cluster-autoscaler/values.yaml

}

function helm-enable-cluster-autoscaling(){
	# Set the ASG tags for cluster autoscaling auto-discovery.
	helm-set-asg-tags

	# Initialize helm
	helm-init

	# Download and configure the cluster-autoscaler.
	helm-get-cluster-autoscaler
 
	# Give the auto-scaler the permissions it needs to work.   
	helm-apply-iam-autoscaling-policy

    # Install the cluster-autoscaler
	cd "$(helm-get-helm-dir)" || exit 1

	
	k8s-kube-ctl create serviceaccount --namespace kube-system tiller \
	 || echo "WARN: Trapped: k8s-kube-ctl create serviceaccount "

	k8s-kube-ctl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller \
	 || echo "WARN: Trapped: k8s-kube-ctl create clusterrolebinding "

	k8s-kube-ctl patch deploy --namespace kube-system tiller-deploy -p '{"spec":{"template":{"spec":{"serviceAccount":"tiller"}}}}' \
	 || echo "WARN: Trapped: k8s-kube-ctl patch deploy "

	sleep 20
	helm-cli install --name myfn cluster-autoscaler


}