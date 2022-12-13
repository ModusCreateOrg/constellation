terraform {
  backend "s3" {
    encrypt = true

    # We can't specify parameterized config here but if we could it would look like:
    # bucket = "tf-state.${project_name}.${aws_region}.${data.aws_caller_identity.current.account_id}"
    dynamodb_table = "TerraformStatelock-k8s-eks-scaling-demo"

    bucket = "tf-state.k8s-eks-scaling-demo.us-west-2.976851222302"
    region = "us-west-2"
    key    = "terraform.tfstate"
  }
}
