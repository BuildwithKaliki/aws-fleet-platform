# Environment: dev
#
# Environments are thin callers. Everything reusable lives in ../../modules.
# To propose a change: edit this file (or the tfvars), open a PR — CI plans it.

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Fill in after bootstrap (see docs/bootstrap.md):
  # backend "s3" {
  #   bucket       = "aws-fleet-platform-dev-tfstate"
  #   key          = "dev/terraform.tfstate"
  #   region       = "eu-west-1"
  #   encrypt      = true
  #   use_lockfile = true
  # }
}

provider "aws" {
  region = var.region
}

variable "region" {
  type    = string
  default = "eu-west-1"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "cluster_role_arn" {
  description = "IAM role for EKS control plane — see docs/bootstrap.md"
  type        = string
}

variable "node_role_arn" {
  description = "IAM role for worker nodes"
  type        = string
}

variable "db_password" {
  type      = string
  default   = "" # empty = module generates + you rotate into Secrets Manager
  sensitive = true
}

locals {
  name = "fleet-${var.environment}"
  # Enforced tagging standard — every module inherits these (FinOps: attributable cost)
  tags = {
    Environment = var.environment
    Project     = "aws-fleet-platform"
    ManagedBy   = "terraform"
    Owner       = "platform-team"
  }
}

module "vpc" {
  source = "../../modules/vpc"

  name = local.name
  tags = local.tags
}

module "eks" {
  source = "../../modules/eks"

  name             = local.name
  subnet_ids       = module.vpc.private_subnet_ids
  cluster_role_arn = var.cluster_role_arn
  node_role_arn    = var.node_role_arn

  node_min_size     = 1
  node_max_size     = 3
  node_desired_size = 1 # dev = cheap
  tags              = local.tags
}

module "db" {
  source = "../../modules/rds"

  name           = "${local.name}-app"
  db_name        = "appdb"
  db_username    = "appadmin"
  db_password    = var.db_password
  subnet_ids     = module.vpc.private_subnet_ids
  vpc_id         = module.vpc.vpc_id
  instance_class = "db.t4g.small" # dev = cheap (FinOps discipline)
  multi_az       = false
  tags           = local.tags
}

output "cluster_name" {
  value = module.eks.cluster_name
}

output "db_endpoint" {
  value = module.db.endpoint
}
