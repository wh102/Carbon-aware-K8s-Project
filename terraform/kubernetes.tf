resource "kubernetes_deployment" "flask_app" {
  metadata {
    name      = "flask-app"
    namespace = kubernetes_namespace.flask_app.metadata[0].name
    labels = {
      app = "flask-app"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "flask-app"
      }
    }

    template {
      metadata {
        labels = {
          app = "flask-app"
        }
      }

      spec {
        container {
          image = "${aws_ecr_repository.flask_app.repository_url}:latest"
          name  = "flask-app"

          port {
            container_port = 5000
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "250m"
              memory = "256Mi"
            }
          }
        }
      }
    }
  }
}


resource "kubernetes_service" "flask_app" {
  metadata {
    name      = "flask-app-service"
    namespace = kubernetes_namespace.flask_app.metadata[0].name
  }

  spec {
    selector = {
      app = "flask-app"
    }

    port {
      port        = 80
      target_port = 5000
    }

    type = "LoadBalancer" 
  }
}

output "flask_app_url" {
  value = kubernetes_service.flask_app.status[0].load_balancer[0].ingress[0].hostname
}
