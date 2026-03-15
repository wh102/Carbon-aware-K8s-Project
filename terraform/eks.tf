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

      ami_type       = "AL2023_ARM_64_STANDARD"
      instance_types = ["t4g.small"]
      use_custom_launch_template = true
      disable_bootstrap_user_data = true

      pre_bootstrap_user_data = <<-EOT
         MIME-Version: 1.0
        Content-Type: multipart/mixed; boundary="=="

        --==
        Content-Type: application/node.eks.aws

        kind: NodeConfig
        apiVersion: node.eks.aws/v1alpha1
        spec:
          kubelet:
            config:
              maxPods: 110
        --==--
      EOT

      metadata_options = {
        http_endpoint               = "enabled"
        http_tokens                 = "required"
        http_put_response_hop_limit = 1
        instance_metadata_tags      = "disabled"
      }

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