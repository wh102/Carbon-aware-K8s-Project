resource "aws_ecr_repository" "flask_app" {
  name         = var.project_name
  force_delete = true

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "metrics_server" {
  name                 = "k8s-metrics-server"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "keda" {
  name                 = "keda"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "kepler" {
  name                 = "kepler"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "prometheus" {
  name                 = "prometheus"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "keda_metrics_adapter" {
  name                 = "keda-metrics-apiserver"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration { scan_on_push = true }
}

resource "aws_ecr_repository" "keda_admission_webhooks" {
  name                 = "keda-admission-webhooks"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration { scan_on_push = true }
}

resource "aws_ecr_repository" "prometheus_operator" {
  name                 = "prometheus-operator"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration { scan_on_push = true }
}

resource "aws_ecr_repository" "aws_ebs_csi_driver" {
  name = "aws-ebs-csi-driver"
}

resource "aws_ecr_repository" "csi_provisioner" {
  name = "csi-provisioner"
}

resource "aws_ecr_repository" "csi_attacher" {
  name = "csi-attacher"
}

resource "aws_ecr_repository" "csi_resizer" {
  name = "csi-resizer"
}

resource "aws_ecr_repository" "csi_snapshotter" {
  name = "csi-snapshotter"
}

resource "aws_ecr_repository" "livenessprobe" {
  name = "livenessprobe"
}

resource "aws_ecr_repository" "aws_load_balancer_controller" {
  name = "aws-load-balancer-controller"
}
