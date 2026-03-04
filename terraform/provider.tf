terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "6.35.0"
     }
    }
  backend "s3" {
    bucket = "carbon-aware-k8s-project"
    key    = "dev/terraform.tfstate"
    region = "eu-west-2"
    dynamodb_table =  "terraform-state-lock"
    encrypt = true
    }
  }
  provider "aws" {
   region = "eu-west-2"
   default_tags {
    tags = {
          Project     = "Carbon-Aware-K8s"
          }
     }
  }
