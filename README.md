# terraform-infrastructure-examples

Terraform examples for provisioning Kubernetes infrastructure — locally and on GCP.
Part of the [DevOps Local Lab](https://github.com/yasin-karagoz/devops-local-lab) learning series.

---

## What this repo contains

Two standalone, ready-to-use Terraform examples:

| Example | Where it runs | What it provisions |
|---|---|---|
| `docker-desktop-k8s` | Your laptop (Docker Desktop) | Namespace, Deployment, Services, Ingress, ConfigMap, PVC |
| `gcp-gke` | Google Cloud | Private GKE cluster, VPC, IAM, two node pools, Cloud NAT |

Each example is independent — you do not need to run one before the other.

---

## Examples

### docker-desktop-k8s

> Deploy a web application to your local Kubernetes cluster. No cloud account needed.

Uses the Kubernetes context provided by Docker Desktop. Good starting point if you want to understand what Terraform looks like when managing Kubernetes resources directly.

What it deploys:
- An nginx-based web app with 2 replicas
- ClusterIP + NodePort services
- An Ingress rule (requires nginx-ingress installed separately)
- A ConfigMap with a custom `index.html`
- A 1Gi PersistentVolumeClaim

```bash
cd examples/docker-desktop-k8s
terraform init
terraform apply
# Open http://localhost:30080
```

[Full documentation →](examples/docker-desktop-k8s/README.md)

---

### gcp-gke

> Provision a production-grade private GKE cluster on Google Cloud.

A real-world GKE setup with security best practices baked in:
- Private cluster (nodes have no public IPs)
- Workload Identity (pods authenticate to GCP without key files)
- Calico network policy (pod-level firewall rules)
- Shielded nodes (secure boot + integrity monitoring)
- Two node pools: `system-pool` (kube-system workloads) and `workload-pool` (your apps)
- Cloud NAT for outbound internet access
- Managed Prometheus

```bash
cd examples/gcp-gke
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars and set project_id
terraform init
terraform apply
```

[Full documentation →](examples/gcp-gke/README.md)

---

## Repository structure

```
terraform-infrastructure-examples/
├── examples/
│   ├── docker-desktop-k8s/
│   │   ├── README.md
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── namespace.tf
│   │   ├── deployment.tf
│   │   ├── service.tf
│   │   ├── ingress.tf
│   │   ├── configmap.tf
│   │   └── pvc.tf
│   └── gcp-gke/
│       ├── README.md
│       ├── providers.tf
│       ├── variables.tf
│       ├── terraform.tfvars.example
│       ├── main.tf
│       ├── network.tf
│       ├── iam.tf
│       └── outputs.tf
└── README.md
```

---

## How this fits into the bigger picture

These examples are for **learning Terraform concepts** with real, working code. They are intentionally self-contained and do not depend on any other repo in the DevOps Local Lab series.

If you want to build a full local platform (cluster + GitOps + monitoring), start with [`local-platform-hub`](https://github.com/yasin-karagoz/local-platform-hub) instead.

| You want to... | Start here |
|---|---|
| Learn Terraform with a quick local example | `examples/docker-desktop-k8s` |
| See a production-ready GKE setup | `examples/gcp-gke` |
| Build a full local DevOps platform | [`local-platform-hub`](https://github.com/yasin-karagoz/local-platform-hub) |

---

## Prerequisites

### For docker-desktop-k8s

- Docker Desktop with Kubernetes enabled
- `terraform >= 1.3.0` — `brew install terraform`
- `kubectl` — `brew install kubectl`

### For gcp-gke

- A GCP project with billing enabled
- `gcloud` CLI authenticated — `gcloud auth application-default login`
- `terraform >= 1.3.0`

GCP APIs that must be enabled:
```bash
gcloud services enable container.googleapis.com compute.googleapis.com iam.googleapis.com \
  --project=YOUR_PROJECT_ID
```
