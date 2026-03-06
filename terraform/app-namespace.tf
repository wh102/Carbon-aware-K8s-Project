resource "kubernetes_namespace" "flask_app" {
  metadata {
    name = "flask-app"
  }
}

resource "kubernetes_resource_quota" "flask_app" {
  metadata {
    name      = "flask-app"
    namespace = kubernetes_namespace.flask_app.metadata[0].name # Link it here!
  }

  spec {
    hard = {
      "requests.cpu"    = "1"
      "requests.memory" = "512Mi"
      "limits.cpu"      = "1.5"
      "limits.memory"   = "1Gi"
    }
  }
}