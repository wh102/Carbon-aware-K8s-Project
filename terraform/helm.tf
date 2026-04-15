resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  namespace  = "kube-system"
  repository = "https://kubernetes-sigs.github.io/metrics-server"
  chart      = "metrics-server"
  wait = false
  set {
    name  = "args"
    value = "{--kubelet-insecure-tls,--kubelet-preferred-address-types=InternalIP}"
  }
  set {
    name  = "image.repository"
    value = aws_ecr_repository.metrics_server.repository_url
  }
  set {
    name  = "image.tag"
    value = "v0.8.0"
  }
}

resource "kubernetes_namespace" "keda" {
  metadata {
    name = "keda"
  }
}

resource "helm_release" "keda" {
  name       = "keda"
  chart      = "keda"
  repository = "https://kedacore.github.io/charts"
  version    = "2.18.3"
  wait = false

  namespace = kubernetes_namespace.keda.metadata[0].name

  set {
    name  = "image.keda.repository"
    value = aws_ecr_repository.keda.repository_url
  }
  set {
    name  = "image.metricsAdapter.repository"
    value = aws_ecr_repository.keda_metrics_adapter.repository_url
  }
  set {
    name  = "image.keda.tag"
    value = "2.18.3"
  }
  set {
    name  = "image.metricsApiServer.tag"
    value = "2.18.3"
  }
  set {
    name  = "image.webhooks.tag"
    value = "2.18.3"
  }
}


resource "helm_release" "aws_lb_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  wait       = false
  timeout    = 900

  set {
    name  = "clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.load_balancer_controller_irsa_role.iam_role_arn
  }

  set {
    name  = "vpcId"
    value = module.vpc.vpc_id
  }

  set {
    name  = "region"
    value = var.aws_region
  }

  depends_on = [module.load_balancer_controller_irsa_role]
  
  set {
    name  = "image.repository"
    value = aws_ecr_repository.aws_load_balancer_controller.repository_url
  }
  
}

resource "helm_release" "prometheus_stack" {
  name             = "prometheus"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = "monitoring"
  create_namespace = true
  wait             = false
  
  set {
    name  = "grafana.enabled"
    value = "false"
  }

  set {
    name  = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.storageClassName"
    value = "gp3"
  }

  set {
    name  = "prometheus.prometheusSpec.resources.requests.memory"
    value = "128Mi"
  }

  set {
    name  = "prometheus.prometheusSpec.image.repository"
    value = aws_ecr_repository.prometheus.repository_url
  }

  set {
    name  = "prometheusOperator.image.repository"
    value = aws_ecr_repository.prometheus_operator.repository_url
  }

  set {
    name  = "prometheus.prometheusSpec.image.tag"
    value = "v2.52.0"
  }
  set {
    name  = "prometheusOperator.image.tag"
    value = "v0.75.0"
  }
}

resource "helm_release" "kepler" {
  name             = "kepler"
  repository       = "https://sustainable-computing-io.github.io/kepler-helm-chart"
  chart            = "kepler"
  namespace        = "monitoring"
  create_namespace = true
  wait             = false

  set {
    name  = "canMountLibModules"
    value = "true"
  }

  set {
    name  = "prometheus.enabled"
    value = "true"
  }

  set {
    name  = "image.repository"
    value = aws_ecr_repository.kepler.repository_url
  }
}

resource "helm_release" "aws_ebs_csi_driver" {
  name       = "aws-ebs-csi-driver"
  repository = "https://kubernetes-sigs.github.io/aws-ebs-csi-driver"
  chart      = "aws-ebs-csi-driver"
  namespace  = "kube-system"
  wait       = false
  force_update  = true
  recreate_pods = true
  
  set {
    name  = "controller.serviceAccount.create"
    value = "true"
  }

  set {
    name  = "controller.serviceAccount.name"
    value = "ebs-csi-controller-sa"
  }

  set {
    name  = "controller.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.ebs_csi_irsa_role.iam_role_arn
  }

  set {
    name  = "sidecars.provisioner.image.repository"
    value = aws_ecr_repository.csi_provisioner.repository_url
  }
  set {
    name  = "sidecars.attacher.image.repository"
    value = aws_ecr_repository.csi_attacher.repository_url
  }
  set {
    name  = "sidecars.resizer.image.repository"
    value = aws_ecr_repository.csi_resizer.repository_url
  }
  set {
    name  = "sidecars.snapshotter.image.repository"
    value = aws_ecr_repository.csi_snapshotter.repository_url
  }
  set {
    name  = "sidecars.livenessProbe.image.repository"
    value = aws_ecr_repository.livenessprobe.repository_url
  }
}