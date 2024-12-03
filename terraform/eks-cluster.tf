module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 18.31.2"

  cluster_name    = "${var.project_name}-${var.environment}-cluster"
  cluster_version = var.cluster_version

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  cluster_ip_family         = "ipv4"
  cluster_service_ipv4_cidr = "10.100.0.0/16"




  cluster_addons = {
    vpc-cni = {
      resolve_conflicts = "OVERWRITE"
    }
    coredns = {
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy         = {}
    aws-ebs-csi-driver = {
      resolve_conflicts = "OVERWRITE"
    }
  }

  # VPC setup
  vpc_id                   = module.cluster_vpc.vpc_id
  subnet_ids               = module.cluster_vpc.private_subnets
  control_plane_subnet_ids = module.cluster_vpc.public_subnets

  node_security_group_additional_rules = {
    ingress_cluster_controller_admission = {
      description                   = "Cluster API to node ingress controller admission"
      protocol                      = "tcp"
      from_port                     = 8443
      to_port                       = 8443
      type                          = "ingress"
      source_cluster_security_group = true
    }
    ingress_cluster_metric_server = {
      description                   = "Cluster API to node to metric server"
      protocol                      = "tcp"
      from_port                     = 4443
      to_port                       = 4443
      type                          = "ingress"
      source_cluster_security_group = true
    },

    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
  }

  # OIDC Identity provider
  cluster_identity_providers = {
    sts = {
      client_id = "sts.amazonaws.com"
    }
  }

  tags = {
    Environment = "eks-cluster"
  }

  # Workers
  eks_managed_node_group_defaults = {
    instance_types = ["t3a.medium", "t3.medium"]

    security_group_rules = {
      outAll = {
        description = ""
        protocol    = "-1"
        from_port   = 0
        to_port     = 0
        type        = "egress"
        cidr_blocks = ["0.0.0.0/0"]
      }
    }
  }

  eks_managed_node_groups = var.eks_nodegroups != null ? local.eks_nodegroups : {}
}

