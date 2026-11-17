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
  description = "Identifier for the database (env-prefixed by the caller)"
  type        = string
}

variable "engine_version" {
  description = "Postgres major version"
  type        = string
  default     = "16.3"
}

variable "instance_class" {
  description = "Instance class - right-size per env; this is the #1 FinOps lever"
  type        = string
  default     = "db.t4g.medium"
}

variable "allocated_storage" {
  type    = number
  default = 50
}

variable "db_name" {
  type = string
}

variable "db_username" {
  type = string
}

variable "db_password" {
  description = "Managed by the caller (SSM/Secrets Manager in real setups) - kept simple here"
  type        = string
  sensitive   = true
}

variable "multi_az" {
  description = "Prod = true, lower envs = false (cost discipline)"
  type        = bool
  default     = false
}

variable "deletion_protection" {
  type    = bool
  default = true
}

variable "final_snapshot" {
  description = "Keep true always - RDS deletes are one-way without it"
  type        = bool
  default     = true
}

variable "subnet_ids" {
  type = list(string)
}

variable "vpc_id" {
  type = string
}

variable "allowed_cidrs" {
  description = "Who can reach the DB (tighten to node/pod CIDRs in real deployments)"
  type        = list(string)
  default     = []
}

variable "tags" {
  type    = map(string)
  default = {}
}

resource "aws_db_subnet_group" "this" {
  name       = var.name
  subnet_ids = var.subnet_ids
  tags       = merge(var.tags, { Name = var.name })
}

resource "aws_security_group" "this" {
  name   = "${var.name}-db"
  vpc_id = var.vpc_id

  dynamic "ingress" {
    for_each = var.allowed_cidrs
    content {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  tags = merge(var.tags, { Name = "${var.name}-db" })
}

resource "aws_db_instance" "this" {
  identifier     = var.name
  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class

  allocated_storage = var.allocated_storage

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.this.id]
  multi_az               = var.multi_az

  storage_encrypted = true

  backup_retention_period = var.multi_az ? 14 : 7
  copy_tags_to_snapshot   = true

  deletion_protection             = var.deletion_protection
  final_snapshot_identifier       = "${var.name}-final"
  skip_final_snapshot             = !var.final_snapshot
  enabled_cloudwatch_logs_exports = ["postgresql"]

  tags = merge(var.tags, { Name = var.name })
}

output "endpoint" {
  value = aws_db_instance.this.address
}

output "port" {
  value = aws_db_instance.this.port
}
