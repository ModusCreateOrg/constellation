Kubernetes EKS Scaling Demo
===========================

This repository houses demo code for Modus Create's Kubernetes and EKS Scaling demo.

The code is based in part on commit 61bee0b7858bbcd3d4276f186cc4cc7bf298ac11 from the [ModusCreateOrg/k8s-eks-scaling-demo](https://github.com/ModusCreateOrg/k8s-eks-scaling-demo/) repository.

 
Instructions
------------

 To run the demo end to end, you will need:
 
* [AWS Account](https://aws.amazon.com/)
* [Docker](https://docker.com/) (tested with 18.05.0-ce)
* [Terraform](https://www.terraform.io/) (tested with  v0.11.7)

Optionally, you can use Jenkins to orchestrate creation of AWS resources in conjunction with GitHub branches and pull requests.

You will also need to set a few environment variables. The method of doing so will vary from platform to platform. 

```
AWS_PROFILE
AWS_DEFAULT_PROFILE
AWS_DEFAULT_REGION
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
```

A [sample file](env.sh.sample) is provided as a template to customize:

```
cp env.sh.sample env.sh
vim env.sh
. env.sh
```

The AWS profile IAM user should have full control of EC2 in the account you are using.

### Jenkins

A `Jenkinsfile` is provided that will allow Jenkins to execute Terraform. In order for Jenkins to do this, it needs to have AWS credentials set up, preferably through an IAM role, granting full control of EC2 and VPC resources in that account. Terraform needs this to create a VPC and EC2 resources. This could be pared down further through some careful logging and role work.

#### Requirements
- An ECR repository to store the images.
- The command line utility 'jq'.
- aws-iam-authenticator
	```
	curl -o /usr/local/bin/aws-iam-authenticator https://amazon-eks.s3-us-west-2.amazonaws.com/1.11.5/2018-12-06/bin/linux/amd64/aws-iam-authenticator
    chmod 755 /usr/local/bin/aws-iam-authenticator
	```
    If 'aws-iam-authenticator' isn't installed, prep.sh will install it from the AWS repository.
- kubectl:
	```
	curl -o /usr/local/bin/kubectl https://amazon-eks.s3-us-west-2.amazonaws.com/1.11.5/2018-12-06/bin/linux/amd64/kubectl
    chmod 755 /usr/local/bin/kubectl
	```
    If 'kubectl' isn't installed, prep.sh will install it from the AWS repository.
### Terraform

This Terraform setup stores its state in Amazon S3 and uses DynamoDB for locking. There is a bit of setup required to bootstrap that configuration. Yu can use [this repository](https://github.com/monterail/terraform-bootstrap-example) to use Terraform to do that bootstrap process. The `backend.tfvars` file in that repo should be modified as follows to work with this project:

(Replace us-east-1 and XXXXXXXXXXXX with the AWS region and your account ID)
```
bucket = "tf-state.k8s-eks-scaling-demo.us-east-1.XXXXXXXXXXXX"
dynamodb_table = "TerraformStatelock-k8s-eks-scaling-demo"
key = "terraform.tfstate"
profile = "terraform"
region = "us-east-1"
```
You'll also need to modify the list of operators who can modify the object in the S3 bucket. Put in the IAM user names of the user into the `setup/variables.tf` file in that project. If your Jenkins instance uses an IAM role to grant access, give it a similar set of permissions to those granted on in the bucket policy to IAM users.

These commands will then set up cloud resources using terraform:
 
    cd terraform
    terraform init
    terraform get
    # Example with values from our environment (replace with values from your environment)
    # terraform plan -var domain=modus.app -out tf.plan
    terraform plan -out tf.plan -var 'domain=example.net'
    terraform apply tf.plan
    # check to see if everything worked - use the same variables here as above
    terraform destroy -var 'domain=example.net'

This assumes that you already have a Route 53 domain in your AWS account created.
You need to either edit variables.tf to match your domain and AWS zone or specify these values as command line `var` parameters.

### Development Notes
- The ECR repositories are not currently created by Terraform. Depending on the goals of the demo they could be managed by Terraform.
- Run './bin/build.sh help' for help on building applications.

# Modus Create

[Modus Create](https://moduscreate.com) is a digital product consultancy. We use a distributed team of the best talent in the world to offer a full suite of digital product design-build services; ranging from consumer facing apps, to digital migration, to agile development training, and business transformation.

[![Modus Create](https://res.cloudinary.com/modus-labs/image/upload/h_80/v1533109874/modus/logo-long-black.png)](https://moduscreate.com)

This project is part of [Modus Labs](https://labs.moduscreate.com).

[![Modus Labs](https://res.cloudinary.com/modus-labs/image/upload/h_80/v1531492623/labs/logo-black.png)](https://labs.moduscreate.com)

# Licensing

This project is [MIT licensed](./LICENSE).

The content in `application` is adapted from _Dimension_ by https://html5up.net/ and is [licensed under a Creative Commons Attribution 3.0 License](https://html5up.net/license) See its [README.md](application/README.md) and [LICENSE.md](application/LICENSE.md) files for more details.

