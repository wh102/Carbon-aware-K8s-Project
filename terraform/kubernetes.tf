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


resource "kubernetes_secret" "mysql_secret" {
  metadata {
    name      = "mysql-secret"
    namespace = kubernetes_namespace.flask_app.metadata[0].name
  }
  data = {
    password = var.db_password
  }
  type = "opaque"
}
