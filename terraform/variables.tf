variable "aws_region" {
  type        = string
  description = "default aws region"
  default     = "eu-west-2"
}

variable "project_name" {
  type        = string
  description = "Name of the project"
  default     = "carbon-aware-k8s-project"
}

variable "vpc_cidr" {
  type        = string
  description = "The CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "db_password" {
  description = "MySQL Root Password"
  type        = string
  sensitive   = true
  default     = "cak8sdb123"
}

variable "github_token" {
  description = "GitHub Personal Access Token for ArgoCD private repo access"
  type        = string
  sensitive   = true
}
