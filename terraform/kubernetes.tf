resource "kubernetes_storage_class_v1" "gp3" {
  metadata {
    name = "gp3"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }
  storage_provisioner    = "ebs.csi.aws.com"
  reclaim_policy         = "Delete"
  allow_volume_expansion = true
  volume_binding_mode    = "WaitForFirstConsumer"
  parameters = {
    type = "gp3"
  }
}

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

          liveness_probe {
            http_get {
              path = "/health"
              port = 5000
            }
            initial_delay_seconds = 5
            period_seconds        = 10
          }
          readiness_probe {
            http_get {
              path = "/health"
              port = 5000
            }
            initial_delay_seconds = 5
            period_seconds        = 5
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

    type = "NodePort"
  }
}

resource "kubernetes_ingress_v1" "flask_app" {
  metadata {
    name      = "flask-app-ingress"
    namespace = kubernetes_namespace.flask_app.metadata[0].name
    annotations = {
      "alb.ingress.kubernetes.io/scheme"      = "internet-facing"
      "alb.ingress.kubernetes.io/target-type" = "ip"
    }
  }
  spec {
    ingress_class_name = "alb"
    rule {
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "flask-app-service"
              port { number = 80 }
            }
          }
        }
      }
    }
  }
}

output "flask_app_url" {
  value = kubernetes_ingress_v1.flask_app.status[0].load_balancer[0].ingress[0].hostname
}