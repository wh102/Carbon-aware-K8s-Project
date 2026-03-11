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

      ami_type       = "AL2023_ARM_64_STANDARD"
      instance_types = ["t4g.small"]

      min_size     = 2
      max_size     = 3
      desired_size = 2
    }
  }

  tags = {
    Environment = "dev"
    Terraform   = "true"
    Region      = var.aws_region
    Default     = var.project_name
  }
}