resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  namespace  = "kube-system"
  repository = "https://kubernetes-sigs.github.io/metrics-server" # Correct URL
  chart      = "metrics-server"

  set {
    name  = "args"
    value = "{--kubelet-insecure-tls}"
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
  version    = "2.13.0"

  namespace = kubernetes_namespace.keda.metadata[0].name
}

module "lb_controller_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.0"

  name = "aws-load-balancer-controller"

  attach_aws_lb_controller_policy = true

  associations = {
    main = {
      cluster_name    = module.eks.cluster_name
      namespace       = "kube-system"
      service_account = "aws-load-balancer-controller"
    }
  }
}

resource "helm_release" "aws_lb_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"

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

  depends_on = [module.lb_controller_pod_identity]
}

resource "helm_release" "prometheus_stack" {
  name             = "prometheus"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = "monitoring"
  create_namespace = true

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
}

resource "helm_release" "kepler" {
  name             = "kepler"
  repository       = "https://sustainable-computing-io.github.io/kepler-helm-chart"
  chart            = "kepler"
  namespace        = "monitoring"
  create_namespace = true

  set {
    name  = "canMountLibModules"
    value = "true"
  }

  set {
    name  = "prometheus.enabled"
    value = "true"
  }
}