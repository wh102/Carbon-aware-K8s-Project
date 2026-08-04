module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = "cluster-cak8s"
  kubernetes_version = "1.31"


  addons = {
    coredns = {
      # image_repository = "982166832404.dkr.ecr.eu-west-2.amazonaws.com/k8s/eks/coredns"
    }
    eks-pod-identity-agent = {
      before_compute   = true
      # image_repository = "982166832404.dkr.ecr.eu-west-2.amazonaws.com/k8s/eks/pod-identity-agent"
    }
    kube-proxy = {
      # image_repository = "982166832404.dkr.ecr.eu-west-2.amazonaws.com/k8s/eks/kube-proxy"
    }
    vpc-cni = {
      before_compute   = true
      # image_repository = "982166832404.dkr.ecr.eu-west-2.amazonaws.com/k8s/amazon-k8s-cni"
      configuration_values = jsonencode({
        env = {
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
        }
      })
    }
    aws-ebs-csi-driver = {
      service_account_role_arn = module.ebs_csi_irsa_role.iam_role_arn
    }
  }
    

  authentication_mode = "API_AND_CONFIG_MAP"

  endpoint_private_access = true
  endpoint_public_access = true

  enable_cluster_creator_admin_permissions = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets



eks_managed_node_groups = {
    example = {
      ami_type       = "AL2_ARM_64" 
      instance_types = ["t4g.small"]

      iam_role_attach_cni_policy = true

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

module "load_balancer_controller_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name                              = "load-balancer-controller-role"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }
}


module "ebs_csi_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name             = "ebs-csi-controller-role"
  attach_ebs_csi_policy = true 

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ebs_csi_extra" {
  role       = module.ebs_csi_irsa_role.iam_role_name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "node_ecr_power" {
  depends_on = [module.eks]

  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
  role       = module.eks.eks_managed_node_groups["example"].iam_role_name
}

resource "aws_iam_policy" "ecr_sync" {
  name        = "ECRSyncPolicy"
  description = "Allows nodes to create pull-through repositories"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ecr:CreateRepository",
          "ecr:BatchImportUpstreamImage",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "node_ecr_sync" {
  depends_on = [module.eks]

  policy_arn = aws_iam_policy.ecr_sync.arn
  role       = module.eks.eks_managed_node_groups["example"].iam_role_name
}
