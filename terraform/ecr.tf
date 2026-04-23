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


resource "aws_ecr_repository" "grafana" {
  name = "grafana"
  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "k8s_sidecar" {
  name = "k8s-sidecar"
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

resource "aws_ecr_repository" "prometheus_operator" {
  name                 = "prometheus-operator"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration { scan_on_push = true }
}

resource "aws_ecr_repository" "alertmanager" {
  name = "alertmanager"
  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "kube_state_metrics" {
  name = "kube-state-metrics"
  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "node_exporter" {
  name = "node-exporter"
  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "kube_webhook_certgen" {
  name = "kube-webhook-certgen"
  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "prometheus_config_reloader" {
  name = "prometheus-config-reloader"
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

resource "aws_ecr_repository" "aws_ebs_csi_driver" {
  name = "aws-ebs-csi-driver"
  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "csi_node_driver_registrar" {
  name = "csi-node-driver-registrar"
  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "csi_provisioner" {
  name = "csi-provisioner"
  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "csi_attacher" {
  name = "csi-attacher"
  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "csi_resizer" {
  name = "csi-resizer"
  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "csi_snapshotter" {
  name = "csi-snapshotter"
  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "livenessprobe" {
  name = "livenessprobe"
  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "aws_load_balancer_controller" {
  name = "aws-load-balancer-controller"
  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "busybox" {
  name = "busybox"
  image_scanning_configuration {
    scan_on_push = true
  }
}


