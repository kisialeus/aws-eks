module "cluster_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.16.0"

  name = "${var.project_name}-cluster-vpc"
  cidr = var.vpc_cidr_block

  azs             = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]
  private_subnets = flatten([for subnet in keys(var.private_subnets) : var.private_subnets[subnet]])
  public_subnets  = var.public_subnets

  enable_nat_gateway     = true
  single_nat_gateway     = false
  one_nat_gateway_per_az = true

  tags = {
    Environment = "eks-cluster"
  }
}
