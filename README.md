# terraform-workflow-example

A reference implementation of the [Platform Deployment Pattern](../Azure-architecture/02-Architecture/IaC/Platform_Deployment_Pattern_2026-05-06.md) — a secure, layered GitHub Actions CI/CD pipeline for Terraform deployments on Azure.

## What this repo shows

- **5-layer deployment model** — `core → data → compute → workloads → edge`, each with isolated state
- **Immutable apply** — the exact binary plan from the `plan` job is applied; no drift between review and execution
- **LocalStack PoC mode** — CI runs against the free `localstack/localstack` Community image on the runner; no auth token, no Azure subscription or credentials needed
- **Per-tier blast radius** — a failure or misconfiguration in one layer cannot affect others
- **Cost visibility on PRs** — OpenInfraQuote shows cost impact fully offline — no API key required
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
│   ├── pull_request_template.md            # PR checklist — enforced on every pull request
│   └── workflows/
│       ├── plan.yml                        # Called on pull_request — plans all layers
│       ├── apply.yml                       # Called on push to main — applies dev → uat → prd
│       ├── changelog.yml                   # Called on release published — updates CHANGELOG.md
│       └── unlock.yml                      # Manual workflow — releases a stuck state lock
│
│   # Pipeline logic lives in the centralized workflow repo:
│   # ext-MarcPar/example-centralize-workflow/.github/workflows/reusable-az-terraform.yml
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
    ├─ cost (core)         OpenInfraQuote offline estimate
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

### Authentication — LocalStack Community (PoC)

In this PoC repo, all Terraform runs target the free `localstack/localstack` Community container started on the GitHub Actions runner. No auth token, Azure subscription, OIDC federation, or Service Principals are needed.

```
GitHub Actions run
    │  docker run localstack/localstack  (free, no token)
    │  generates localstack.override.tf (azurerm provider → localhost:4566)
    ▼
LocalStack Community
    │  intercepts provider API calls (AWS-focused, Azure is limited in free tier)
    │  proves pipeline wiring: init → plan → apply → release all run clean
    ▼
Terraform azurerm provider
    │  uses metadata_host = "localhost.localstack.cloud:4566"
    │  subscription_id   = "00000000-0000-0000-0000-000000000000" (dummy)
    │  no resources use the provider yet — provider is downloaded but not called
```

When copying this template to a real product repo, replace LocalStack with OIDC-based Azure authentication — see [Wiring to real Azure](#wiring-to-real-azure-when-copying-to-a-product-repo) below.

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

## Setup (PoC — LocalStack)

No Azure credentials, subscription IDs, state storage, or LocalStack auth tokens are needed.

### 1 — GitHub: Environments

Create one environment per tier per environment in **Settings → Environments**. Naming convention: `<tier>-<environment>` (e.g. `core-dev`, `data-uat`, `compute-prd`).

No secrets or environment variables are required for the PoC.

Configure required reviewers:

| Environment pattern | Required reviewers |
|---|---|
| `*-dev` | None (auto-deploys) |
| `*-uat` | 1 × product team |
| `*-prd` | 2 × product team + platform team |

### 4 — Branch protection

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

**Disable cost analysis** — set `run_cost_analysis: false` in the `plan.yml` `with:` block. The `cost-analysis` job and the cost section in PR comments will be skipped automatically.

**Disable security checks** — set `run_security_checks: false` in `plan.yml`. Not recommended for production.

**Add a second product to the same BU** — create a new repo (`terraform-<bu>-<product2>01`), copy this template, update the `remote.tf` locals. The same BU apply SPs (`sp-<bu>-prd`, etc.) are reused; add a new federated credential per tier per environment for the new repo.

---

## Wiring to real Azure (when copying to a product repo)

This PoC runs against LocalStack. When you copy this template to a real product repo, make these changes:

1. **`versions.tf` in each layer** — change `backend "local" {}` to `backend "azurerm" { use_oidc = true }`; remove the azurerm `required_providers` block if you prefer to keep versions in the provider block instead

2. **`remote.tf` in each layer** — uncomment the `state_backend` locals and `data "terraform_remote_state"` blocks; update `bu_code` and `product_name` to match your repo variables

3. **Centralized workflow** — update the SHA reference in `plan.yml` and `apply.yml` to a production-ready commit of `ext-MarcPar/example-centralize-workflow`. See that repo's README for the full secrets interface and OIDC federated credential setup.

4. **Create Azure Service Principals** — one Reader SP for plan runs (two federated credentials: `pull_request` and `ref:refs/heads/main` subjects) and one Apply SP per environment (federated credential per tier per environment using `environment:<tier>-<env>` subject)

5. **Add GitHub repo secrets/variables** — `AZURE_TENANT_ID`, `AZURE_CLIENT_ID_PLAN`, `AZURE_SUBSCRIPTION_ID_DEV/UAT/PRD`, `TF_STATE_RESOURCE_GROUP`, `TF_STATE_STORAGE_ACCOUNT`, `TF_STATE_CONTAINER`

6. **Add `AZURE_CLIENT_ID_APPLY` to each GitHub Environment** — the apply job reads this directly from the environment context (callers cannot pass environment-level variables as secrets)

---

## Troubleshooting

**`Error: No such file or directory: tfplan.binary`**
The plan job did not upload the artifact, or the artifact name in the apply job doesn't match. Check that `github.sha` is the same between the plan and apply jobs (it will be — they run in the same workflow run on push to main).

**`LocalStack did not become ready within 2 minutes`**
The `localstack/localstack` image failed to start or the health endpoint isn't responding. Check the "Start LocalStack" step logs for docker errors. The image is public and requires no auth to pull.

**`Error acquiring the state lock`**
With `backend "local"` each job uses ephemeral state — this shouldn't occur in PoC mode. If it happens after wiring to `backend "azurerm"`, use `terraform force-unlock <lock-id>`.

**Cost analysis shows `$0` for everything**
OpenInfraQuote runs fully offline and supports a subset of resource types. Check the `oiq-comment.md` artifact in the workflow run for details. If a resource type is unsupported it will be skipped silently.
