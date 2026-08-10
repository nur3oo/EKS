#!/usr/bin/env bash
# Fills the cert ARN and ALB security group id from terraform outputs into the
# uptime-kuma ingress template.
# Usage: ./scripts/render-ingress.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "${SCRIPT_DIR}")"
TF_DIR="${REPO_ROOT}/terraform"
TEMPLATE="${REPO_ROOT}/kubernetes/ingress/uptime-kuma-ingress.yaml.tmpl"
OUTPUT="${REPO_ROOT}/kubernetes/ingress/uptime-kuma-ingress.yaml"

CERT_ARN="$(terraform -chdir="${TF_DIR}" output -raw cert_arn)"
ALB_SG_ID="$(terraform -chdir="${TF_DIR}" output -raw alb_sg_id)"

sed \
  -e "s|__CERT_ARN__|${CERT_ARN}|g" \
  -e "s|__ALB_SG_ID__|${ALB_SG_ID}|g" \
  "${TEMPLATE}" > "${OUTPUT}"

echo "Rendered ${OUTPUT}"
