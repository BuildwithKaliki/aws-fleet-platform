# Bootstrap Guide

From zero to a working platform lane.

## 1. Prerequisites

- AWS CLI v2, Terraform >= 1.6, kubectl
- An AWS account with admin (sandbox is fine — use `aws-vault` or SSO profiles if you have several)
- A GitHub repo with this code pushed

## 2. One-time: state backend

Each environment gets its own S3 state bucket + DynamoDB lock table. Bootstrapping is
chicken-and-egg (Terraform state about Terraform state), so it's a one-time manual run:

```bash
cd environments/dev
export TF_STATE_BUCKET=aws-fleet-platform-dev-tfstate
export TF_STATE_TABLE=aws-fleet-platform-dev-locks
export AWS_REGION=eu-west-1

aws s3 mb s3://$TF_STATE_BUCKET
aws dynamodb create-table \
  --table-name $TF_STATE_TABLE \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST

# then fill in the backend block in main.tf and:
terraform init
```

Repeat for stage/prod (separate buckets — never share state between environments).

## 3. Allow GitHub Actions to run Terraform without long-lived keys

Create an OIDC provider + a role per environment that the workflow assumes. Easiest way:
run the `modules/github-oidc` pattern from any bootstrap account, or configure it manually:

- Provider URL: `https://token.actions.githubusercontent.com`
- Trust policy: your repo + branch `main` (apply) / any PR (plan-only, no write)

Then export the role ARN as the repo secret `AWS_ROLE_ARN_DEV` (and `_STAGE`/`_PROD`).

## 4. First plan + apply

```bash
cd environments/dev
terraform init && terraform plan
# review — expect: VPC, EKS control plane + nodegroup, RDS, tags
terraform apply
```

Then open a PR touching `environments/dev/*.tfvars` and watch the CI lane produce the
same plan. That's the workflow your app teams would live in.

## 5. kubeconfig

```bash
aws eks update-kubeconfig --name fleet-dev --region eu-west-1
kubectl get nodes
```

## 6. Teardown (avoid surprise bills)

```bash
# everything, in reverse order
cd environments/dev && terraform destroy
```

The RDS module keeps `final_snapshot = true` by default — the destroy will create one
last snapshot; delete it manually if you truly want everything gone.
