resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  namespace  = "kube-system"
  repository = "https://kubernetes-sigs.github.io/metrics-server"
  chart      = "metrics-server"
  wait       = true
  set {
    name  = "args[0]"
    value = "--kubelet-insecure-tls"
  }
  set {
    name  = "args[1]"
    value = "--kubelet-preferred-address-types=InternalIP"
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
  wait       = false

  namespace = kubernetes_namespace.keda.metadata[0].name

  depends_on = [helm_release.aws_lb_controller, helm_release.metrics_server]

  set {
    name  = "image.keda.repository"
    value = aws_ecr_repository.keda.repository_url
  }
  set {
    name  = "image.keda.tag"
    value = "2.18.3"
  }
  set {
    name  = "image.keda.registry"
    value = ""
  }

  set {
    name  = "image.metricsAdapter.repository"
    value = aws_ecr_repository.keda_metrics_adapter.repository_url
  }
  set {
    name  = "image.metricsAdapter.tag"
    value = "2.18.3"
  }
  set {
    name  = "image.metricsAdapter.registry"
    value = ""
  }

  set {
    name  = "image.webhooks.repository"
    value = aws_ecr_repository.keda_admission_webhooks.repository_url
  }
  set {
    name  = "image.webhooks.tag"
    value = "2.18.3"
  }
  set {
    name  = "image.webhooks.registry"
    value = ""
  }

}


resource "helm_release" "aws_lb_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  wait       = true
  timeout    = 600

  depends_on = [
    module.eks,
    module.load_balancer_controller_irsa_role
  ]

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

}

data "aws_caller_identity" "current" {}

locals {
  ecr_registry = "${data.aws_caller_identity.current.account_id}.dkr.ecr.eu-west-2.amazonaws.com"
}

resource "helm_release" "prometheus_stack" {
  name             = "prometheus"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = "monitoring"
  create_namespace = true
  wait             = true
  timeout          = 900

  depends_on = [
    helm_release.aws_lb_controller,
    helm_release.metrics_server
  ]

  set {
    name  = "grafana.enabled"
    value = "true"
  }

  set {
    name  = "grafana.image.registry"
    value = local.ecr_registry
  }

  set {
    name  = "grafana.image.repository"
    value = aws_ecr_repository.grafana.name
  }

  set {
    name  = "grafana.image.tag"
    value = "12.4.3"
  }

  set {
    name  = "prometheus.prometheusSpec.image.registry"
    value = local.ecr_registry
  }

  set {
    name  = "prometheus.prometheusSpec.image.repository"
    value = aws_ecr_repository.prometheus.name
  }

  set {
    name  = "prometheus.prometheusSpec.image.tag"
    value = "v3.11.2"
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
    name  = "prometheus.prometheusSpec.retention"
    value = "7d"
  }

  set {
    name  = "prometheusOperator.image.registry"
    value = local.ecr_registry
  }

  set {
    name  = "prometheusOperator.image.repository"
    value = aws_ecr_repository.prometheus_operator.name
  }

  set {
    name  = "prometheusOperator.image.tag"
    value = "v0.90.1"
  }

  set {
    name  = "prometheusOperator.prometheusConfigReloader.image.registry"
    value = local.ecr_registry
  }

  set {
    name  = "prometheusOperator.prometheusConfigReloader.image.repository"
    value = aws_ecr_repository.prometheus_config_reloader.name
  }

  set {
    name  = "prometheusOperator.prometheusConfigReloader.image.tag"
    value = "v0.90.1"
  }

  set {
    name  = "kubeStateMetrics.image.registry"
    value = local.ecr_registry
  }

  set {
    name  = "kubeStateMetrics.image.repository"
    value = aws_ecr_repository.kube_state_metrics.name
  }

  set {
    name  = "kubeStateMetrics.image.tag"
    value = "v2.18.0"
  }

  set {
    name  = "nodeExporter.image.registry"
    value = local.ecr_registry
  }

  set {
    name  = "nodeExporter.image.repository"
    value = aws_ecr_repository.node_exporter.name
  }

  set {
    name  = "nodeExporter.image.tag"
    value = "v1.11.1"
  }

  set {
    name  = "alertmanager.enabled"
    value = "false"
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
    name  = "extraEnv[0].name"
    value = "ENABLE_GPU"
  }

  set {
    name  = "extraEnv[0].value"
    value = "false"
  }

  set {
    name  = "extraEnv[1].name"
    value = "ENABLE_EBPF_CGROUPID"
  }

  set {
    name  = "extraEnv[1].value"
    value = "false"
  }

  set {
    name  = "extraEnv[2].name"
    value = "EXPOSE_HW_COUNTER_METRICS"
  }

  set {
    name  = "extraEnv[2].value"
    value = "false"
  }

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

  set {
    name  = "image.tag"
    value = "v0.11.4-arm64"
  }
}
