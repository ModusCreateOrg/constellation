module "demo-cluster" {
  source       = "github.com/terraform-aws-modules/terraform-aws-eks?ref=v4.0.2"
  cluster_name = "${var.project_name}-cluster"
  subnets      = ["${module.vpc.public_subnets}"]
  vpc_id       = "${module.vpc.vpc_id}"

  worker_groups = [
    {
      instance_type = "m5.large"
      asg_max_size  = 5
    },
  ]

  tags = {
    environment = "${var.project_name}-devel"
  }
}
