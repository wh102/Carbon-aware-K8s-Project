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