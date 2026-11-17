terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

variable "name" {
  description = "Cluster name"
  type        = string
}

variable "kubernetes_version" {
  description = "EKS control plane version"
  type        = string
  default     = "1.30"
}

variable "subnet_ids" {
  description = "Private subnet IDs for the cluster and nodes"
  type        = list(string)
}

variable "node_min_size" {
  type    = number
  default = 2
}

variable "node_max_size" {
  type    = number
  default = 6
}

variable "node_desired_size" {
  type    = number
  default = 2
}

variable "node_instance_types" {
  type    = list(string)
  default = ["t3.medium"]
}

variable "cluster_role_arn" {
  description = "Pre-existing IAM role for the EKS control plane (created outside so the module stays composable)"
  type        = string
}

variable "node_role_arn" {
  description = "Pre-existing IAM role for worker nodes (least privilege, ECR + SSM + CNI policies)"
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

resource "aws_eks_cluster" "this" {
  name     = var.name
  role_arn = var.cluster_role_arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  tags = merge(var.tags, { Name = var.name })
}

resource "aws_eks_node_group" "default" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.name}-default"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.subnet_ids

  scaling_config {
    desired_size = var.node_desired_size
    min_size     = var.node_min_size
    max_size     = var.node_max_size
  }

  instance_types = var.node_instance_types

  tags = merge(var.tags, { Name = "${var.name}-ng" })

  labels = { "fleet/nodegroup" = "default" }
}

output "cluster_name" {
  value = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority" {
  value = aws_eks_cluster.this.certificate_authority[0].data
}

output "oidc_provider_url" {
  value = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

output "node_group_arn" {
  value = aws_eks_node_group.default.arn
}
