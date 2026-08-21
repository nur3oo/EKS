#!/usr/bin/env bash
# Fills the cert ARN from terraform outputs into the uptime-kuma ingress template.
# Usage: ./scripts/render-ingress.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "${SCRIPT_DIR}")"
TF_DIR="${REPO_ROOT}/terraform"
TEMPLATE="${REPO_ROOT}/kubernetes/ingress/uptime-kuma-ingress.yaml.tmpl"
OUTPUT="${REPO_ROOT}/kubernetes/ingress/uptime-kuma-ingress.yaml"

CERT_ARN="$(terraform -chdir="${TF_DIR}" output -raw cert_arn)"

sed \
  -e "s|__CERT_ARN__|${CERT_ARN}|g" \
  "${TEMPLATE}" > "${OUTPUT}"

echo "Rendered ${OUTPUT}"
