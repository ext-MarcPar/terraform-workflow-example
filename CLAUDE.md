# CLAUDE.md — terraform-workflow-example

Reference implementation of the Onterris Platform Deployment Pattern.
Source architecture: `Azure-architecture/02-Architecture/IaC/Platform_Deployment_Pattern_2026-05-06.md`
Detailed design decisions: `Azure-architecture/02-Architecture/IaC/Platform_Deployment_Pattern_Followups_2026-05-11.md`

---

## What this repo is

A **workflow template** — not a deployed product. Its purpose is to be copied as the starting
point for `terraform-<bu>-<product>01` per-product repos. The Terraform layer files are stubs
showing the structure; the GitHub Actions workflows are the primary artifact.

Do not add real Azure resource declarations here. Keep this repo as a clean, copyable template.

---

## Repo structure

```
.github/
  CODEOWNERS                       ownership model — edit when the team structure changes
  actions/tf-layer/action.yml      composite action used by plan.yml and apply.yml
  workflows/
    reusable-az-terraform.yml      ALL deployment logic lives here — single file to maintain
    plan.yml                       thin caller: one job per layer, on pull_request
    apply.yml                      thin caller: 15 jobs (5 layers × 3 envs), on push to main
    changelog.yml                  fires on release: published — updates CHANGELOG.md

core/       L1 — networking, observability, UAMIs (required)
data/       L2 — KV, ACR, PostgreSQL, private endpoints (required)
compute/    L3 — AKS, App Service Plan (required)
workloads/  L4 — cluster bootstrap (optional — delete if not needed)
edge/       L5 — Front Door, WAF (optional — delete if not needed)
```

---

## Key design decisions (don't change without reviewing the source docs)

**Layer ordering** — core → data → compute → [workloads + edge peer-optional]. Upstream state
must exist before downstream layers can plan. L4 and L5 both depend on L3; they do not depend
on each other.

**`remote.tf` consolidation** — each layer reads ALL upstream state in a single `remote.tf`.
Sub-modules never call `data "terraform_remote_state"` directly; they receive values as
variables from `main.tf`. This is an enforced code-review rule.

**Identity in L1 Core** — UAMIs are created in `core/` so their `principal_id` is available
for L2 role assignments before any compute resource exists. Never move UAMI creation to L2 or L3.

**OIDC only** — `ARM_USE_OIDC=true` on every job. No client secrets anywhere. Plan runs use a
Reader SP; apply runs use per-env apply SPs scoped to the GitHub Environment.

**Immutable apply** — the `plan` job uploads `tfplan.binary` as an artifact; the `apply` job in
the same workflow run downloads and applies it. No re-plan on apply.

**Concurrency lock** — `group: repo-tier-environment`, `cancel-in-progress: false`. This protects
the Azure blob state lock. Do not change `cancel-in-progress` to `true`.

---

## Working with this repo

### Editing workflow logic
Deployment logic (validate → plan → cost → PR comment → apply → release) is in
`reusable-az-terraform.yml`. The `plan.yml` and `apply.yml` callers are intentionally
thin — they only pass inputs and secrets.

Changelog logic is in `changelog.yml` — a separate workflow that fires on every published
release. To change how CHANGELOG.md is formatted or committed, edit only `changelog.yml`.
Do not add changelog logic back into `reusable-az-terraform.yml` — the separation is
intentional (a changelog commit failure must not block or roll back a completed apply).

### Adding or removing a layer
1. Add or remove the layer directory (`workloads/`, `edge/`)
2. Add or remove the corresponding jobs in `plan.yml` (one job per layer)
3. Add or remove the corresponding jobs in `apply.yml` (three jobs per layer — dev, uat, prd)
4. Update the `needs:` chain to maintain the correct dependency order

### Adding an environment (e.g. staging between uat and prd)
1. Duplicate the UAT job block in `apply.yml`, rename to `staging`
2. Update `needs:` on the PRD jobs to depend on `staging`
3. Create the GitHub Environments (`core-staging`, `data-staging`, etc.)
4. Set `AZURE_CLIENT_ID_APPLY` and `AZURE_SUBSCRIPTION_ID` in each new environment

### Updating action SHA pins
All `uses:` references in `reusable-az-terraform.yml` and `action.yml` should be pinned to
full commit SHAs (not tags) in production repos. The template uses tag aliases for readability.
Update them by looking up the current SHA for each action's release tag on GitHub.

### Updating `remote.tf` when copying to a new product repo
In every layer's `remote.tf`, update the `state_backend` locals and the `bu_code` /
`product_name` locals to match the new product's `BU_CODE` and `PRODUCT_NAME` repo variables.

---

## Variables and secrets reference

### Repository-level variables
| Variable | Description |
|---|---|
| `BU_CODE` | 2-char BU code (e.g. `ct`) |
| `PRODUCT_NAME` | Product + instance suffix (e.g. `example01`) |
| `AZURE_TENANT_ID` | Entra ID tenant ID |
| `AZURE_CLIENT_ID_PLAN` | Reader SP client ID — used by `plan.yml` |
| `AZURE_SUBSCRIPTION_ID_DEV` | Dev subscription ID — used by `plan.yml` for backend auth |
| `TF_STATE_RESOURCE_GROUP` | State storage account resource group |
| `TF_STATE_STORAGE_ACCOUNT` | State storage account name |
| `TF_STATE_CONTAINER` | State blob container name |

### Per-environment variables (set in each GitHub Environment)
| Variable | Description |
|---|---|
| `AZURE_CLIENT_ID_APPLY` | Apply SP client ID for this environment |
| `AZURE_SUBSCRIPTION_ID` | Product subscription ID for this environment |

### Repository secrets
| Secret | Description |
|---|---|
| `INFRACOST_API_KEY` | Infracost API key — omit to skip cost analysis |

---

## State key convention

```
<bu_code>/<product_name>/<layer>/terraform.tfstate
```

Example for `terraform-ct-example01`:
```
ct/example01/core/terraform.tfstate
ct/example01/data/terraform.tfstate
ct/example01/compute/terraform.tfstate
ct/example01/workloads/terraform.tfstate
ct/example01/edge/terraform.tfstate
```

All five keys live in the same storage account and container. The plan SP needs
`Storage Blob Data Reader` on the container (or the `ct/example01/` prefix).
The apply SPs need `Storage Blob Data Contributor` scoped to their own prefix.
