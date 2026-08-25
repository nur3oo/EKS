<div align="center">

<img src="https://readme-typing-svg.demolab.com?font=Fira+Code&size=28&pause=1000&color=F7A600&center=true&vCenter=true&width=500&lines=EKS+Uptime+Kuma;Running+on+AWS+EKS" alt="Typing SVG" />

![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white)

</div>

---

## What is Uptime Kuma?

Uptime Kuma is an open source self-hosted monitoring tool. Monitor websites, APIs, and services and get alerted when something goes down. Lightweight, clean UI, and easy to self-host in a container.

---

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

## Key features
## Kubernetes

This project runs on EKS with everything managed through GitOps. Nothing gets deployed with kubectl apply, every change goes through Git and ArgoCD picks it up from there.

- **ArgoCD** runs an app of apps pattern, one root Application watches this repo and creates every other Application automatically, including managing its own Helm release.
- **AWS Load Balancer Controller** provisions ALBs from Ingress resources, using IRSA for permissions instead of static credentials.
- **Prometheus and Grafana** give visibility into node and pod level metrics with dashboards.
- **Ingress Controller** routes external traffic in and works with the LB controller so each app gets its own ALB listener.
- **Helm** packages and templates every workload in the cluster, including ArgoCD itself, with values managed in Git.

## Terraform

Terraform handles the infrastructure layer, everything that has to exist before GitOps can take over.

- **EKS Cluster** and node groups, fully defined as code and reproducible from scratch.
- **VPC** with subnets, routing, and a NAT Gateway for outbound access. I didn't use VPC endpoints here, they're more secure and often cheaper on data transfer, but the number needed to cover ECR, S3, STS, CloudWatch, ArgoCD, Prometheus, and Grafana across multiple AZs added up in both setup time and fixed hourly cost, so a single NAT Gateway was the simpler trade-off for this project.
- **IAM Roles** for IRSA (in cluster workloads) and GitHub OIDC (CI/CD), both scoped with least privilege trust policies.

Terraform's job stops at bootstrapping the cluster and installing ArgoCD. From there, everything else lives in Git.
## Docker

* Containerised the application for consistency and portability across environments.
* Set up Docker layer caching to cut down build times.
* Used multi-stage builds to keep image size down for faster deployments.
* Ran the container as a non-root user to reduce security risk.
* Used immutable image tags so deployments stay reproducible.
