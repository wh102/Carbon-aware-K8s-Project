resource "kubernetes_namespace" "flask_app" {
  metadata {
    name = "flask-app"
  }
}
