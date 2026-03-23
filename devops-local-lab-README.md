# DevOps Local Lab

> Learn DevOps locally before touching the cloud.

No AWS account. No GCP bill. Everything runs on your laptop using Docker Desktop.

This repository is the companion to the **DevOps Local Lab** YouTube channel.
Each folder maps directly to a video series — clone it, follow along, and build
a fully working DevOps environment on your machine.

---

## Why local-first?

Most DevOps tutorials start with a cloud account and a credit card.
This series starts with Docker Desktop and builds up from there —
so you understand every layer before you ever touch a cloud provider.

---

## Learning Path

| # | Series | What you build | Folder |
|---|---|---|---|
| 1 | Linux for DevOps | Commands, scripting, permissions | `linux/` |
| 2 | Docker Fundamentals | Images, containers, compose | `docker/` |
| 3 | Local Kubernetes Lab | Kind cluster + local registry | `projects/01-local-k8s-cluster/` |
| 4 | Platform Stack | ArgoCD + Ingress + Prometheus + Grafana | `projects/02-platform-stack/` |
| 5 | Helm Charts | Build and publish your own charts | `projects/05-helm-charts/` |
| 6 | GitOps with ArgoCD | Deploy apps via Git | `projects/02-platform-stack/` |
| 7 | Observability | Metrics, dashboards, alerts | `projects/04-finops-operator/` |
| 8 | Terraform Automation | Automate everything above | all `projects/` |

---

## Prerequisites

Everything you need on your laptop:

```sh
brew install terraform kind kubectl helm
```

And [Docker Desktop](https://www.docker.com/products/docker-desktop/) (v4.27.2 for macOS 12).

---

## Quick Start

```sh
git clone https://github.com/yasin-karagoz/kubernetes-local-lab
cd kubernetes-local-lab/projects/01-local-k8s-cluster

terraform init
terraform apply

export KUBECONFIG=$(terraform output -raw kubeconfig_path)
kubectl get nodes
```

---

## Projects

### Project 01 — Local Kubernetes Cluster
A 3-node Kind cluster with a local Docker registry wired in.
The foundation everything else builds on.

```
1 control-plane  (ports 80/443 mapped to your Mac)
2 workers
localhost:5001   (local Docker registry)
```

→ [View project](projects/01-local-k8s-cluster/)

---

### Project 02 — Platform Stack
Full GitOps + observability platform deployed with Terraform and Helm.

```
https://argocd.localhost      GitOps UI
https://grafana.localhost     Metrics dashboards
https://prometheus.localhost  Metrics scraping
```

→ [View project](projects/02-platform-stack/) *(coming soon)*

---

### Project 03 — Self-Service Database Operator
A Go Kubernetes operator. Create a `DatabaseRequest` CR, get a running database
and a connection secret injected into your namespace automatically.

→ [View project](projects/03-db-provisioner/) *(coming soon)*

---

### Project 04 — FinOps Operator
A Go operator that compares resource requests vs actual usage and emits
Prometheus metrics surfacing waste. Includes a Grafana dashboard.

→ [View project](projects/04-finops-operator/) *(coming soon)*

---

### Project 05 — Custom Helm Chart Library
Three reusable base charts (`base-app`, `base-cronjob`, `base-worker`) served
from a local ChartMuseum instance running in the cluster.

→ [View project](projects/05-helm-charts/) *(coming soon)*

---

### Project 06 — Local GitHub Actions
Run GitHub Actions workflows on your laptop with `act`. No CI minutes needed.

→ [View project](projects/06-local-github-actions/) *(coming soon)*

---

## Reproducible labs

Every project ships with a `scripts/reset-and-test.sh` that destroys and
recreates the environment from scratch, then runs smoke tests.

Run it before following any tutorial to confirm your setup is clean:

```sh
cd projects/01-local-k8s-cluster
./scripts/reset-and-test.sh
```

---

## Channel

**YouTube:** [DevOps Local Lab](https://youtube.com/@yasinkaragoz) *(link coming soon)*

New videos every week following the learning path above.

---

## License

MIT
