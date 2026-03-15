module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = "cluster-cak8s"
  kubernetes_version = "1.31"

  addons = {
    coredns = {}
    eks-pod-identity-agent = {
      before_compute = true
    }
    kube-proxy = {}
    vpc-cni = {
      before_compute = true
      configuration_values = jsonencode({
        env = {
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
        }
      })
    }
    aws-ebs-csi-driver = {
      most_recent = true
    }
  }


  endpoint_public_access = true


  enable_cluster_creator_admin_permissions = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets



eks_managed_node_groups = {
    example = {
      ami_type       = "AL2_ARM_64" 
      instance_types = ["t4g.small"]

      bootstrap_extra_args = "--kubelet-extra-args '--max-pods=110'"

      pre_bootstrap_user_data = <<-EOT
         export ENABLE_PREFIX_DELEGATION=true
         export WARM_PREFIX_TARGET=1
      EOT

      min_size     = 2
      max_size     = 3
      desired_size = 2
      
      
      iam_role_additional_policies = {
        ebs_csi_policy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
      }
    }
}

  tags = {
    Environment = "dev"
    Terraform   = "true"
    Region      = var.aws_region
    Default     = var.project_name
  }
}