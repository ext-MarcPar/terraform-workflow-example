.DEFAULT_GOAL := help

LAYERS := core data compute workloads edge

# ── Help ──────────────────────────────────────────────────────────────────────
.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
	  | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}' \
	  | sort

# ── LocalStack lifecycle ──────────────────────────────────────────────────────
.PHONY: ls-start
ls-start: ## Start LocalStack Azure container (requires LOCALSTACK_AUTH_TOKEN)
	@if [ -z "$$LOCALSTACK_AUTH_TOKEN" ]; then \
	  echo "ERROR: LOCALSTACK_AUTH_TOKEN is not set."; \
	  echo "       Export it first: export LOCALSTACK_AUTH_TOKEN=<your-token>"; \
	  exit 1; \
	fi
	docker compose -f docker-compose.localstack.yml up -d
	@echo "Waiting for LocalStack to become healthy..."
	@until docker inspect localstack-azure --format='{{.State.Health.Status}}' 2>/dev/null | grep -q healthy; do \
	  printf "."; sleep 2; \
	done
	@echo ""
	@echo "LocalStack is ready at http://localhost:4566"

.PHONY: ls-stop
ls-stop: ## Stop and remove LocalStack Azure container
	docker compose -f docker-compose.localstack.yml down

.PHONY: ls-status
ls-status: ## Show LocalStack health and running services
	@curl -sf http://localhost:4566/_localstack/health | python3 -m json.tool 2>/dev/null \
	  || echo "LocalStack is not running (curl failed)"

# ── Terraform init ────────────────────────────────────────────────────────────
.PHONY: ls-init
ls-init: ## Generate override files and run terraform init for all layers
	bash scripts/ls-init.sh

# ── Terraform plan ────────────────────────────────────────────────────────────
.PHONY: ls-plan
ls-plan: ## Plan all layers against LocalStack (in dependency order)
	@for layer in $(LAYERS); do \
	  echo ""; \
	  echo "==> terraform plan ($$layer)"; \
	  cd $$layer && terraform plan -no-color 2>&1 && cd ..; \
	done

.PHONY: ls-plan-core
ls-plan-core: ## Plan core layer only
	cd core && terraform plan

.PHONY: ls-plan-data
ls-plan-data: ## Plan data layer only
	cd data && terraform plan

.PHONY: ls-plan-compute
ls-plan-compute: ## Plan compute layer only
	cd compute && terraform plan

.PHONY: ls-plan-workloads
ls-plan-workloads: ## Plan workloads layer only
	cd workloads && terraform plan

.PHONY: ls-plan-edge
ls-plan-edge: ## Plan edge layer only
	cd edge && terraform plan

# ── Terraform apply ───────────────────────────────────────────────────────────
.PHONY: ls-apply
ls-apply: ## Apply all layers against LocalStack (in dependency order)
	@for layer in $(LAYERS); do \
	  echo ""; \
	  echo "==> terraform apply ($$layer)"; \
	  cd $$layer && terraform apply -auto-approve -no-color 2>&1 && cd ..; \
	done

.PHONY: ls-apply-core
ls-apply-core: ## Apply core layer only
	cd core && terraform apply -auto-approve

.PHONY: ls-apply-data
ls-apply-data: ## Apply data layer only
	cd data && terraform apply -auto-approve

.PHONY: ls-apply-compute
ls-apply-compute: ## Apply compute layer only
	cd compute && terraform apply -auto-approve

.PHONY: ls-apply-workloads
ls-apply-workloads: ## Apply workloads layer only
	cd workloads && terraform apply -auto-approve

.PHONY: ls-apply-edge
ls-apply-edge: ## Apply edge layer only
	cd edge && terraform apply -auto-approve

# ── Terraform destroy ─────────────────────────────────────────────────────────
.PHONY: ls-destroy
ls-destroy: ## Destroy all layers in reverse order
	@for layer in edge workloads compute data core; do \
	  echo ""; \
	  echo "==> terraform destroy ($$layer)"; \
	  cd $$layer && terraform destroy -auto-approve -no-color 2>&1 && cd ..; \
	done

# ── Teardown ──────────────────────────────────────────────────────────────────
.PHONY: ls-teardown
ls-teardown: ## Remove all LocalStack override files and local state files
	bash scripts/ls-teardown.sh

.PHONY: ls-clean
ls-clean: ls-destroy ls-stop ls-teardown ## Destroy infra, stop container, remove override files
