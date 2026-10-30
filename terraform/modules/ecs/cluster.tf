terraform {
  required_providers {
     aws = {
        source = "hashicorp/aws"
        version = "~>6.0"
    }
  }
}

variable "environment" {}

locals {
    prefix = var.environment
}

resource "aws_ecs_cluster" "cloudsave-cluster" {
    name = "cloudsave-cluster-${local.prefix}"
    setting {
        name = "containerInsights"
        value = "enhanced"
    }
}
