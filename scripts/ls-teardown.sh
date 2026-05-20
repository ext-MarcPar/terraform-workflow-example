#!/usr/bin/env bash
# scripts/ls-teardown.sh
# Removes all LocalStack override files and local state files.
# Does NOT stop the LocalStack container — use `make ls-stop` for that.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LAYERS=(core data compute workloads edge)

echo ""
echo "==> Removing LocalStack override files"
for layer in "${LAYERS[@]}"; do
  for f in \
    "${REPO_ROOT}/${layer}/localstack.override.tf" \
    "${REPO_ROOT}/${layer}/localstack.auto.tfvars" \
    "${REPO_ROOT}/${layer}/terraform.localstack.tfstate" \
    "${REPO_ROOT}/${layer}/terraform.localstack.tfstate.backup"
  do
    if [ -f "$f" ]; then
      rm -f "$f"
      echo "  removed ${f#"$REPO_ROOT/"}"
    fi
  done
done

echo ""
echo "==> Done. Override files removed."
echo "    Layers will use the real azurerm backend on next terraform init."
