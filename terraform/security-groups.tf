resource "aws_security_group" "outbound" {
  name        = "${var.project_name}-outbound"
  description = "Grants instances all outbound access"
  vpc_id      = "${module.vpc.vpc_id}"

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"

    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  tags {
    Project = "${var.project_name}"
  }
}

resource "aws_security_group" "ssh" {
  name        = "${var.project_name}-ssh"
  description = "Grants access to ssh"
  vpc_id      = "${module.vpc.vpc_id}"

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = "${var.trusted_cidr_blocks}"
  }

  tags {
    Project = "${var.project_name}"
  }
}

resource "aws_security_group" "web" {
  name        = "${var.project_name}-web"
  description = "Allows access to common web ports"
  vpc_id      = "${module.vpc.vpc_id}"

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"

    cidr_blocks = [
      "0.0.0.0/0", # Everyone
    ]
  }

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"

    cidr_blocks = [
      "0.0.0.0/0", # Everyone
    ]
  }

  tags {
    Project = "${var.project_name}"
  }
}

resource "aws_security_group" "icmp" {
  name        = "${var.project_name}-icmp"
  description = "Allows access to ping"
  vpc_id      = "${module.vpc.vpc_id}"

  # Allow ICMP echo
  # https://github.com/hashicorp/terraform/issues/1313#issuecomment-107619807
  ingress {
    from_port = -1
    to_port   = -1
    protocol  = "icmp"
    self      = true
  }

  tags {
    Project = "${var.project_name}"
  }
}
