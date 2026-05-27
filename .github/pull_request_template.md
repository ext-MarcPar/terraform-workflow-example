## Summary

> Describe what changed and why. Link to any related issues or tickets.

## Type of change

- [ ] New resource / module
- [ ] Existing resource update
- [ ] Layer restructure
- [ ] Workflow / pipeline change
- [ ] Bug fix
- [ ] Documentation only

---

## Checklist

### Terraform plan
- [ ] Plan output reviewed in the PR comments (posted automatically by `plan.yml`)
- [ ] No unexpected resource **destroys** — any intentional destroys are explicitly called out below
- [ ] No unexpected resource **replacements** (`-/+`) — immutable property changes are justified
- [ ] `No changes` is expected where no changes were intended

### Security
- [ ] No secrets, passwords, or access keys hardcoded in `.tf` files or YAML configs
- [ ] New managed identities use `principal_type = "ServicePrincipal"` on role assignments
- [ ] New storage accounts / Key Vaults follow security defaults (`public_network_access_enabled = false`, TLS 1.2, etc.)
- [ ] Private endpoints added for any new resources that support them

### State and dependencies
- [ ] `remote.tf` updated if new upstream state references are added
- [ ] Immutable properties (PostgreSQL SKU, Container App Environment zone redundancy, KV soft-delete) set correctly on first apply
- [ ] `lifecycle { prevent_destroy = true }` added to production resources where applicable

### Cost
- [ ] Cost impact reviewed in the PR comments (posted automatically by OpenInfraQuote)
- [ ] Unexpected cost increases flagged and approved by product owner

### Workflow
- [ ] Centralized workflow SHA in `plan.yml` / `apply.yml` is up to date
- [ ] If `.github/` files were changed, platform team approval obtained (see CODEOWNERS)

---

> **Reminder:** Verify AI-generated Terraform before merging — plan output is the source of truth, not the code.
