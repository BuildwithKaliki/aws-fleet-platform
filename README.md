# aws-fleet-platform

**Multi-account, multi-region AWS platform factory — Kubernetes the way platform teams build it.**

Reference implementation of production platform patterns: composable Terraform modules, environment stacks as thin callers, GitOps-friendly cluster builds, and CI lanes that make every change flow through plan → review → apply.

> Full code (modules, environments, CI workflows) is being pushed from local — this README will be updated by the initial import commit.

## Principles baked in

1. **Environments are copy-paste** — new env = new folder + tfvars
2. **Everything through PRs** — CI plans on every PR; apply only on merge
3. **Remote state + locking** — S3 + DynamoDB per environment, never shared
4. **Least privilege by default** — GitHub OIDC, no static keys
5. **Cost-visible** — tagging standard enforced at module level
