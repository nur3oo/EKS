<div align="center">

<img src="https://readme-typing-svg.demolab.com?font=Fira+Code&size=28&pause=1000&color=F7A600&center=true&vCenter=true&width=500&lines=EKS+Uptime+Kuma;Running+on+AWS+EKS" alt="Typing SVG" />

![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white)

</div>

---

## What is Uptime Kuma?

Uptime Kuma is an open source self-hosted monitoring tool. Monitor websites, APIs, and services and get alerted when something goes down. Lightweight, clean UI, and easy to self-host in a container.

## Architecture diagram
<img width="545" height="727" alt="Screenshot 2026-08-31 203611" src="https://github.com/user-attachments/assets/8bb84422-ebe0-4907-a5ad-e3450d6789aa" />


---
## Tech Stack

**Infrastructure**:
Terraform · AWS EKS · VPC · IAM (IRSA + OIDC) · NAT Gateway · ACM

**GitOps & Kubernetes**:
ArgoCD · Helm · AWS Load Balancer Controller · Ingress NGINX · cert-manager · external-dns

**Observability**:
Prometheus · Grafana · kube-prometheus-stack

**CI/CD**:
GitHub Actions · GitHub OIDC (no static AWS creds)

**App & Containers**:
Docker (multi-stage builds, non-root user, layer caching) · Uptime Kuma
## Key features
## Kubernetes
Everything runs through GitOps. No kubectl apply, every change goes through Git and ArgoCD syncs it.

- **ArgoCD** - One root Application creates every other Application, including its own Helm release.
- **AWS Load Balancer Controller** - provisions ALBs from Ingress resources, using IRSA instead of static credentials.
- **Prometheus and Grafana** - node and pod level metrics with dashboards.
- **Ingress Controller** - routes external traffic, works with the LB controller so each app gets its own ALB listener.
- **Helm** - packages every workload including ArgoCD itself, values managed in Git.

## Terraform
Handles the infrastructure layer, everything that needs to exist before GitOps takes over.

- **EKS Cluster** and node groups, fully defined as code.
- **VPC** with subnets, routing, and a NAT Gateway for outbound access. Skipped VPC endpoints, covering ECR, S3, STS, CloudWatch, ArgoCD, Prometheus and Grafana across multiple AZs added up in setup time and fixed cost, NAT Gateway was the simpler trade-off here.
- **IAM Roles** for IRSA and GitHub OIDC, both least privilege.

Terraform's job stops at bootstrapping the cluster and installing ArgoCD. Everything else lives in Git.

## CI/CD

Every workflow is manually triggered (`workflow_dispatch`) with a confirm input, no auto-apply on push. Auth is via GitHub OIDC, no static AWS credentials.

- **terraform-plan**: runs `terraform plan` to check drift before applying.
- **terraform-apply**: applies the infra, then applies the ArgoCD root Application, handing off to GitOps.
- **push-image**: builds and pushes the Uptime Kuma image to ECR, tagged with the commit SHA.
- **destroy**: deletes ArgoCD-managed apps first so the LB controller can clean up its ALBs, then runs `terraform destroy`. Wrong order leaves orphaned ALBs and stuck subnets.

## Docker
- Containerised the app for consistency across environments
- Docker layer caching to cut build times
- Multi-stage builds to keep image size down
- Non-root user to reduce security risk
- Immutable image tags for reproducible deployments

## Repo Structure
```
EKS/
├── .github/
│   └── workflows/
│       ├── destroy.yaml
│       ├── push-image.yaml
│       ├── terraform-apply.yaml
│       └── terraform-plan.yaml
│
├── terraform/
│   ├── main.tf, variables.tf, output.tf, provider.tf, backend.tf
│   ├── vpc/
│   ├── eks/
│   ├── iam/
│   ├── sg/
│   ├── certs/
│   ├── argocd/
│   └── bootstrap/
│
├── kubernetes/
│   ├── apps/                      # ArgoCD app manifests
│   │   ├── root.yaml
│   │   ├── argocd.yaml
│   │   ├── cert-manager.yaml
│   │   ├── external-dns.yaml
│   │   ├── ingress-nginx.yaml
│   │   ├── lb-controller.yaml
│   │   ├── monitoring.yaml
│   │   └── uptime-kuma.yaml
│   ├── cert-manager/
│   │   └── cluster-issuer.yaml
│   ├── monitoring/
│   │   └── values/
│   │       └── base.yaml          # kube-prometheus-stack Helm values
│   └── uptime-kuma/
│       ├── deployment.yaml
│       ├── ingress.yaml
│       └── service.yaml
│
├── uptime-kuma/                    # vendored app source, custom Docker build
└── README.md
```

## Architectural Trade-offs

### NAT Gateway vs VPC Endpoints

**Started with:** VPC Endpoints only (S3, ECR, STS) no NAT Gateway, to avoid its hourly and data processing costs.

**Problem:** Endpoints only cover AWS service traffic. ArgoCD-managed workloads pulling public Helm charts and images not mirrored to ECR had no internet egress path.

**Switched to:** NAT Gateway for general internet egress.

**Trade-off:** Accepted NAT Gateway's cost for the flexibility of not needing an ECR mirror or custom endpoint for every new dependency. Right call for iteration speed on a portfolio project; at production scale I'd revisit actual NAT data costs and consider tightening egress further.

---

### Terraform vs ArgoCD Ownership Split

**Boundary:** Terraform owns infrastructure and bootstrap only VPC, EKS cluster, IAM, security groups, and a one-time ArgoCD install. ArgoCD owns everything that runs inside the cluster from that point on.

**Why:** Keeps two different change cadences separate. Infra changes are rare and higher-risk (`terraform apply`); workload changes are frequent and lower-risk (Git commit, auto-synced). Mixing them means every app update carries the blast radius of a Terraform run.

**Trade-off:** Requires discipline to not "just add it to Terraform" when something's quicker to bootstrap that way. Debugging also means knowing which layer to look in, Terraform state or ArgoCD sync status, when something's broken.

### ArgoCD Self-Management

**Setup:** The root Application also manages ArgoCD's own Helm release, so ArgoCD upgrades itself through the same GitOps loop as every other workload.

**Risk:** If a bad ArgoCD version or Helm values change gets synced, the component responsible for detecting and fixing drift could itself be the broken, GitOps can't self-heal from the POV that the healer is unhealthy.

**Mitigation:** Recovery falls outside GitOps in this case: a direct `helm rollback argocd` or manual `kubectl` intervention against the cluster, bypassing Git temporarily until ArgoCD is healthy again and can resume managing itself.

## Running Locally

Uptime Kuma was first validated locally using Docker Compose before being deployed to EKS.

The v1 image is used over v2 because v2 ships with an embedded MariaDB that requires Unix socket support, which does not work on WSL2 or Docker Desktop. v1 runs on SQLite and works out of the box.

```bash
cd uptime-kuma
cd docker
docker compose -f docker-compose-dev.yml up
```

Open `http://localhost:3001` in your browser.
<img width="1892" height="838" alt="Screenshot 2026-05-09 155917" src="https://github.com/user-attachments/assets/5f81a019-2f31-4298-b6f4-7a897913bb8e" />



## Deployed application with domain

<img width="1912" height="1020" alt="Screenshot 2026-08-29 141653" src="https://github.com/user-attachments/assets/04f2f8c8-1eab-48a6-8f7e-d1e303c9113b" />

## Grafana: Deployed through ArgoCD to visualise cluster and pod metrics with real-time dashboards.
<img width="1902" height="1017" alt="Screenshot 2026-08-29 142432" src="https://github.com/user-attachments/assets/d3914003-4c64-40df-8659-7fc3e06a343e" />
Cluster view. CPU requests are well above actual usage (24.6% requested vs 4.20% used), giving space but leaving room to right-size. Memory runs the other way, usage sits above requests (37.1% vs 13.1%), worth increasing memory since the memory risks eviction under pressure as the workload increases.

## Future Improvements
- **Persistent storage for Prometheus**, no `storageSpec` set, so a pod restart wipes all metrics history.
- **Ingress rate limiting / WAF**, public ingress has no rate limiting or WAF in front of it.
- **Blue/green or canary rollout for app updates**, currently a plain rolling update, no traffic shifting or automated rollback on failure.
