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
