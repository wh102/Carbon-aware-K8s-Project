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

resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
}
resource "kubernetes_secret" "argocd_repo_creds" {
  metadata {
    name      = "private-repo-creds"
    namespace = kubernetes_namespace.argocd.metadata[0].name
    labels = {
      "argocd.argoproj.io/secret-type" = "repository"
    }
  }

  data = {
    type     = "git"
    url      = "https://github.com/wh102/Carbon-aware-K8s-Project.git"
    username = "wh102"
    password = var.github_token
  }
}


resource "kubernetes_secret" "mysql_secret" {
  metadata {
    name      = "mysql-secret"
    namespace = kubernetes_namespace.flask_app.metadata[0].name
  }

  data = {
    password = base64encode(var.db_password)
  }

  type = "Opaque"
}

resource "kubernetes_service_account" "ebs_csi" {
  metadata {
    name      = "ebs-csi-controller-sa"
    namespace = "kube-system"

    annotations = {
      "eks.amazonaws.com/role-arn" = module.ebs_csi_irsa_role.iam_role_arn
    }
  }
}