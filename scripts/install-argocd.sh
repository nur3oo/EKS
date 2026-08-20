#!/usr/bin/env bash
# Waits for the EKS cluster (and at least one Ready node) to exist, then installs ArgoCD.
# Usage: ./scripts/install-argocd.sh [cluster-name] [region]

set -euo pipefail

CLUSTER_NAME="${1:-eks-cluster}"
REGION="${2:-eu-west-2}"
ARGOCD_NAMESPACE="argocd"
ARGOCD_MANIFEST="https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"
POLL_INTERVAL=15

echo "Waiting for EKS cluster '${CLUSTER_NAME}' in ${REGION} to become ACTIVE..."
while true; do
  status="$(aws eks describe-cluster \
    --name "${CLUSTER_NAME}" \
    --region "${REGION}" \
    --query 'cluster.status' \
    --output text 2>/dev/null || echo "MISSING")"

  echo "  cluster status: ${status}"
  [[ "${status}" == "ACTIVE" ]] && break
  sleep "${POLL_INTERVAL}"
done

echo "Cluster is ACTIVE. Updating kubeconfig..."
aws eks update-kubeconfig --name "${CLUSTER_NAME}" --region "${REGION}"

echo "Waiting for at least one node to be Ready..."
while true; do
  ready_count="$(kubectl get nodes --no-headers 2>/dev/null \
    | awk '$2 == "Ready"' | wc -l)"

  echo "  ready nodes: ${ready_count}"
  [[ "${ready_count}" -ge 1 ]] && break
  sleep "${POLL_INTERVAL}"
done

echo "Installing ArgoCD into namespace '${ARGOCD_NAMESPACE}'..."
kubectl create namespace "${ARGOCD_NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n "${ARGOCD_NAMESPACE}" -f "${ARGOCD_MANIFEST}" --server-side --force-conflicts

echo "Waiting for argocd-server to roll out..."
kubectl rollout status deployment/argocd-server -n "${ARGOCD_NAMESPACE}" --timeout=300s

echo
echo "ArgoCD installed. Initial admin password:"
kubectl -n "${ARGOCD_NAMESPACE}" get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d
echo
echo
echo "Port-forward with: kubectl port-forward svc/argocd-server -n argocd 8080:443"
