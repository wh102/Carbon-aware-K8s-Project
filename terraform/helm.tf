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