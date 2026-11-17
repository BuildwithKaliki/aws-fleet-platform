# Architecture Decision Records

Lightweight pattern: date-ordered files, one decision each.

Template (`docs/adr/NNNN-short-title.md`):

```markdown
# ADR NNNN: Short title

Date: YYYY-MM-DD
Status: proposed | accepted | superseded by ADR-XXXX

## Context
What forces are at play.

## Decision
What we're doing.

## Consequences
The good, the bad, and how we live with it.
```

Decisions to record early (suggested):

1. **State-per-environment** — why dev/stage/prod never share a backend
2. **Modules live in-repo vs registry** — speed vs versioning discipline
3. **EKS managed nodegroups vs Fargate vs Karpenter** — cost/control tradeoff
4. **GitHub OIDC over static keys** — security posture
5. **Terragrunt? (no — plain composition for now)** — simplicity argument
