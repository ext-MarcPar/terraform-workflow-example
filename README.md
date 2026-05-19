# terraform-workflow-example

A reference implementation of the [Platform Deployment Pattern](../Azure-architecture/02-Architecture/IaC/Platform_Deployment_Pattern_2026-05-06.md) — a secure, layered GitHub Actions CI/CD pipeline for Terraform deployments on Azure.

## What this repo shows

- **5-layer deployment model** — `core → data → compute → workloads → edge`, each with isolated state
- **Immutable apply** — the exact binary plan from the `plan` job is applied; no drift between review and execution
- **OIDC-only auth** — no stored credentials; Azure SPs authenticated via GitHub's federated identity tokens
- **Per-tier blast radius** — a failure or misconfiguration in one layer cannot affect others
- **Cost visibility on PRs** — Infracost shows monthly cost impact before any reviewer approves
- **Automated release trail** — every successful apply updates `CHANGELOG.md` and creates a GitHub Release

---

## Repository structure

```
.
├── .github/
│   ├── CODEOWNERS                          # Ownership + required reviewers per path
│   ├── actions/
│   │   └── tf-layer/
│   │       └── action.yml                  # Composite action: tf init + plan or apply
│   └── workflows/
│       ├── reusable-az-terraform.yml       # Core reusable workflow (all logic lives here)
│       ├── plan.yml                        # Called on pull_request — plans all layers
│       ├── apply.yml                       # Called on push to main — applies dev → uat → prd
│       └── changelog.yml                   # Called on release published — updates CHANGELOG.md
│
├── core/                                   # L1: VNet, NSGs, LAWS, UAMIs, DNS zones
│   ├── versions.tf
│   ├── variables.tf
│   ├── main.tf
│   └── outputs.tf
│
├── data/                                   # L2: Key Vault, ACR, PostgreSQL, private endpoints
│   ├── versions.tf
│   ├── variables.tf
│   ├── remote.tf                           # Reads core state — single source of truth
│   ├── main.tf
│   └── outputs.tf
│
├── compute/                                # L3: AKS cluster or App Service Plan
│   ├── versions.tf
│   ├── remote.tf                           # Reads core + data state
│   ├── main.tf
│   └── outputs.tf
│
├── workloads/                              # L4: Cluster bootstrap — optional
│   ├── versions.tf
│   ├── remote.tf                           # Reads core + data + compute state
│   └── main.tf
│
└── edge/                                   # L5: Front Door, WAF policy — optional
    ├── versions.tf
    ├── remote.tf                           # Reads core + compute state
    └── main.tf
```

---

## Layer model

```
L1 Core         (required)  — networking, observability, identity
    ↓
L2 Data         (required)  — databases, Key Vault, ACR, private endpoints
    ↓
L3 Compute      (required)  — AKS, App Service Plan, VMs
    ↓
    ├─→ L4 Workloads  (optional)  — K8s cluster bootstrap, AVD scaffolding
    └─→ L5 Edge       (optional)  — Front Door, WAF, custom domains
```

**L4 and L5 are peer-optional** — both depend on L3 but not on each other. Skip either if the product doesn't need it:

- **Skip L4** for App Service or pure-VM products where app code ships via the dev team's pipeline.
- **Skip L5** for AVD-only, internal-only, or products that use the App Service built-in FQDN.

Each layer has **isolated Terraform state** — a failure in L4 cannot corrupt L1–L3 state. Cross-layer references use `data "terraform_remote_state"` reads consolidated in each layer's `remote.tf`.

---

## Workflow overview

### On pull request → `plan.yml`

```
PR opened / updated
    │
    ├─ validate (core)     fmt check + tflint + Checkov
    │       ↓
    ├─ plan (core)         terraform plan → upload artifact
    │       ↓
    ├─ cost (core)         Infracost diff
    │       ↓
    ├─ pr-comment (core)   unified comment: summary + plan + cost
    │
    └─ (same chain for data → compute → workloads + edge in parallel)
```

Each layer posts its own collapsible PR comment. Previous comments for the same layer are deleted before posting so the PR stays clean.

### On push to main → `apply.yml`

```
Merge to main
    │
    ├─ DEV (auto — no approvers required)
    │   core-dev → data-dev → compute-dev → workloads-dev + edge-dev
    │                                               ↓
    ├─ UAT (requires 1 approval from product team)
    │   core-uat → data-uat → compute-uat → workloads-uat + edge-uat
    │                                               ↓
    └─ PRD (requires 2 approvals: product team + platform team)
        core-prd → data-prd → compute-prd → workloads-prd + edge-prd
```

Each apply job:
1. Downloads the exact plan binary uploaded during the `plan` job in this run
2. Waits for the GitHub Environment approval gate
3. Runs `terraform apply tfplan.binary` — no re-plan, no drift
4. Creates a GitHub Release with resource-level change details

### On release published → `changelog.yml`

```
GitHub Release published (by apply workflow)
    │
    └─ update-changelog
         reads release tag, name, body, published_at
         prepends formatted entry to CHANGELOG.md
         commits back to main [skip ci]
```

This is a separate workflow rather than a step inside the apply workflow because:
- It decouples changelog management from the deployment pipeline — a failed changelog commit cannot block or roll back an apply
- It fires for **any** published release, including manually created ones
- It creates a clean audit trail independent of which tier or environment triggered the release
- The `[skip ci]` commit tag prevents the push from re-triggering the apply workflow

---

## Security model

### Authentication — OIDC only

No client secrets or long-lived credentials are stored anywhere. GitHub issues a short-lived OIDC ID token per workflow run. Azure validates the token against the federated credential registered on the Service Principal and returns a scoped access token.

```
GitHub Actions run
    │  issues OIDC ID token
    │  (subject: repo:org/repo:environment:core-prd)
    ▼
Azure Entra ID
    │  validates against federated credential on sp-ct-prd
    │  returns access token (1-hour TTL, scoped to CT prd subscription)
    ▼
Terraform azurerm provider / backend
    │  uses ARM_USE_OIDC=true + ARM_CLIENT_ID + ARM_TENANT_ID + ARM_SUBSCRIPTION_ID
```

### Four permission layers

| Layer | Mechanism | What it gates |
|---|---|---|
| Repo access | GitHub teams | Who can push branches and open PRs |
| PR merge | CODEOWNERS + branch protection | Which paths require which team's approval |
| Workflow trigger | GitHub Environments + required reviewers | Whether the Apply SP token is issued |
| Azure apply | OIDC federation + Azure RBAC | What the SP can actually do in Azure |

### OIDC token exfiltration risk

The Apply SP typically has Owner on the product subscription. A single-line change to a workflow file can exfiltrate the SP's access token during a legitimate apply run.

Mitigations built into this template:

- `/.github/` requires approval from both `PRODUCT_LEADS` and `platform-team` in CODEOWNERS
- Branch protection requires approval from someone other than the author
- GitHub Environment gates require explicit human approval before the Apply SP token is issued
- Plan runs use a separate Reader SP (`AZURE_CLIENT_ID_PLAN`) — exfiltrating a plan-run token gets read-only access only
- Federated credential subject is scoped to a specific environment (`environment:core-prd`), not just the branch

**Pin all action `uses:` references to full commit SHAs in production.** Tag references (`@v4`) are mutable and vulnerable to supply-chain attacks where the tag is moved to point at malicious code.

### Concurrency control

```yaml
concurrency:
  group: ${{ github.repository }}-${{ inputs.tier }}-${{ inputs.environment }}
  cancel-in-progress: false
```

Prevents two runs from colliding on the Azure blob state lock for the same tier + environment. `cancel-in-progress: false` queues the second run rather than cancelling it — safe for infrastructure changes where you don't want to silently discard a pending deploy.

---

## Setup

### 1 — Azure: create Service Principals

Create one SP per BU per environment plus one Reader SP for plan runs:

| SP name | Azure RBAC scope | Role | Used for |
|---|---|---|---|
| `sp-<bu>-plan` | All product subscriptions | Reader | PR plan runs (all tiers) |
| `sp-<bu>-dev` | Dev subscription | Owner (or custom deployer) | Dev apply runs |
| `sp-<bu>-uat` | UAT subscription | Owner | UAT apply runs |
| `sp-<bu>-prd` | Prd subscription | Owner | Prd apply runs |

Register federated credentials on each SP:

```bash
# Plan SP — one credential per repo, using pull_request subject
az ad app federated-credential create \
  --id <plan-sp-app-id> \
  --parameters '{
    "name": "tf-example01-plan",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:onterris/terraform-ct-example01:pull_request",
    "audiences": ["api://AzureADTokenExchange"]
  }'

# Apply SP (prd) — one credential per environment per repo
az ad app federated-credential create \
  --id <prd-sp-app-id> \
  --parameters '{
    "name": "tf-example01-core-prd",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:onterris/terraform-ct-example01:environment:core-prd",
    "audiences": ["api://AzureADTokenExchange"]
  }'
# Repeat for each tier+environment combination (data-prd, compute-prd, etc.)
```

### 2 — Terraform state storage

Provision the state storage account in the platform subscription:

```bash
az group create -n pl-tfstate-prd-rg -l eastus2
az storage account create \
  -n onterristfstateprd \
  -g pl-tfstate-prd-rg \
  --sku Standard_LRS \
  --min-tls-version TLS1_2 \
  --https-only true \
  --allow-blob-public-access false
az storage container create -n tfstate --account-name onterristfstateprd
```

Grant the plan SP and apply SPs `Storage Blob Data Contributor` on the container (or scope to specific blob path prefixes for tighter RBAC).

### 3 — GitHub: repository variables

Set these in **Settings → Secrets and variables → Actions → Variables**:

| Variable | Example value | Description |
|---|---|---|
| `BU_CODE` | `ct` | 2-character BU code |
| `PRODUCT_NAME` | `example01` | Product name + instance suffix |
| `AZURE_TENANT_ID` | `xxxxxxxx-...` | Entra ID tenant ID |
| `AZURE_CLIENT_ID_PLAN` | `xxxxxxxx-...` | Reader SP client ID |
| `AZURE_SUBSCRIPTION_ID_DEV` | `xxxxxxxx-...` | Dev subscription ID (plan workflow uses this) |
| `TF_STATE_RESOURCE_GROUP` | `pl-tfstate-prd-rg` | State storage RG |
| `TF_STATE_STORAGE_ACCOUNT` | `onterristfstateprd` | State storage account name |
| `TF_STATE_CONTAINER` | `tfstate` | State blob container |

Set this in **Secrets**:

| Secret | Description |
|---|---|
| `INFRACOST_API_KEY` | From [infracost.io/docs](https://www.infracost.io/docs/#2-get-api-key) — remove if not using cost analysis |

### 4 — GitHub: Environments

Create one environment per tier per environment in **Settings → Environments**. Naming convention: `<tier>-<environment>` (e.g. `core-dev`, `data-uat`, `compute-prd`).

For each environment, set:

| Variable | Value |
|---|---|
| `AZURE_CLIENT_ID_APPLY` | Apply SP client ID for this environment |
| `AZURE_SUBSCRIPTION_ID` | Product subscription ID for this environment |

Configure required reviewers:

| Environment pattern | Required reviewers |
|---|---|
| `*-dev` | None (auto-deploys) |
| `*-uat` | 1 × product team |
| `*-prd` | 2 × product team + platform team |

### 5 — Update `remote.tf` locals

In each layer's `remote.tf`, update the `state_backend` locals to match your actual state storage account, and update `bu_code` and `product_name` to match your `BU_CODE` and `PRODUCT_NAME` repo variables:

```hcl
# data/remote.tf
locals {
  state_backend = {
    resource_group_name  = "pl-tfstate-prd-rg"      # ← your state RG
    storage_account_name = "onterristfstateprd"      # ← your state SA
    container_name       = "tfstate"
    use_oidc             = true
  }
  bu_code      = "ct"         # ← your BU_CODE
  product_name = "example01"  # ← your PRODUCT_NAME
}
```

### 6 — Branch protection

Enable these rules on `main` in **Settings → Branches**:

- Require a pull request before merging
- Require approvals: 1 minimum
- Require review from Code Owners
- Require status checks to pass: all `Validate` and `Plan` jobs
- Dismiss stale pull request approvals when new commits are pushed
- Require linear history
- Do not allow bypassing the above settings

---

## `remote.tf` consolidation pattern

Each tier reads all upstream state **once** in `remote.tf` at the tier root. The tier's `main.tf` passes values as variables into per-project sub-modules. Sub-modules never call `data "terraform_remote_state"` directly.

```
data/remote.tf          reads core state once
      ↓
data/main.tf            passes values as variables
      ├─→ module.shared    receives pe_subnet_id, laws_id, etc.
      └─→ module.project1  receives pe_subnet_id, kv_id from module.shared
```

**Enforcement rule:** if you see `data "terraform_remote_state"` inside a sub-module directory (e.g. `data/project1/main.tf`), move it to the tier root's `remote.tf`. This is a code-review rule; it can also be enforced in CI:

```bash
find . -path './*/*/**.tf' | xargs grep -l 'terraform_remote_state' && exit 1 || exit 0
```

---

## Adapting this template

**Remove optional layers** — delete the `workloads/` or `edge/` directories and remove the corresponding jobs from `plan.yml` and `apply.yml`.

**Change the environment count** — to add a `staging` environment between UAT and PRD, duplicate the UAT job block in `apply.yml`, change the `environment:` values, and add a corresponding GitHub Environment.

**Disable cost analysis** — set `run_cost_analysis: false` in the `plan.yml` `with:` block, or remove the `INFRACOST_API_KEY` secret. The `cost-analysis` and `pr-comment` cost section will be skipped automatically.

**Disable security checks** — set `run_security_checks: false` in `plan.yml`. Not recommended for production.

**Add a second product to the same BU** — create a new repo (`terraform-<bu>-<product2>01`), copy this template, update the `PRODUCT_NAME` variable and `remote.tf` locals. The same BU apply SPs (`sp-<bu>-prd`, etc.) are reused; add a new federated credential per tier per environment for the new repo.

---

## Troubleshooting

**`Error: No such file or directory: tfplan.binary`**
The plan job did not upload the artifact, or the artifact name in the apply job doesn't match. Check that `github.sha` is the same between the plan and apply jobs (it will be — they run in the same workflow run on push to main).

**`Error: Backend configuration changed`**
The `-backend-config` flags don't match the backend block. Ensure `versions.tf` has `backend "azurerm" { use_oidc = true }` with no other attributes — all config is injected by CI.

**`AADSTS70011: The provided request must include a 'scope' input parameter`**
The federated credential subject doesn't match the workflow context. Verify the `subject` in the Azure federated credential matches the GitHub environment name exactly (e.g. `repo:org/repo:environment:core-prd`).

**`Error acquiring the state lock`**
Another run is already applying the same tier + environment. The concurrency group prevents new runs from starting, but if a run was cancelled mid-apply the lock may be left in Azure. Use `terraform force-unlock <lock-id>` to release it manually.

**Cost analysis shows `$0` for everything**
Infracost requires a valid API key and the resource types to be supported. Check the Infracost output in the workflow logs. Some Azure resource types have limited Infracost support.
