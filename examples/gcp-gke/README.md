# Example — GCP GKE Cluster

Provision a production-grade private GKE cluster on Google Cloud using Terraform.
Includes VPC networking, two node pools, IAM, Workload Identity, and managed Prometheus.

## What this example creates

| Resource | Description |
|---|---|
| VPC + Subnet | Dedicated network for GKE nodes with secondary ranges for pods and services |
| GKE Cluster | Regional private cluster with Workload Identity and Calico network policy |
| System Node Pool | Runs kube-system workloads (CoreDNS, monitoring agents) — tainted so only system pods land here |
| Workload Node Pool | Runs your application workloads with autoscaling |
| Service Account | Dedicated GCP service account for GKE nodes with least-privilege IAM roles |
| Cloud NAT | Allows private nodes to reach the internet without public IPs |

## Prerequisites

- A GCP project with billing enabled
- `gcloud` CLI installed and authenticated
- Terraform `>= 1.3.0`
- The following GCP APIs enabled in your project:
  - `container.googleapis.com`
  - `compute.googleapis.com`
  - `iam.googleapis.com`

```sh
# Install tools
brew install terraform google-cloud-sdk

# Authenticate
gcloud auth application-default login

# Enable required APIs
gcloud services enable container.googleapis.com compute.googleapis.com iam.googleapis.com \
  --project=YOUR_PROJECT_ID
```

## Quick start

**1. Copy and fill in your variables:**

```sh
cd examples/gcp-gke
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and set at minimum:

```hcl
project_id = "your-gcp-project-id"
region     = "us-central1"
```

**2. Initialise and apply:**

```sh
terraform init
terraform plan   # review what will be created
terraform apply
```

Takes ~10-15 minutes for the cluster to fully provision.

**3. Connect kubectl to the cluster:**

```sh
gcloud container clusters get-credentials $(terraform output -raw cluster_name) \
  --region $(terraform output -raw region) \
  --project YOUR_PROJECT_ID

kubectl get nodes
```

## Variables

| Variable | Default | Description |
|---|---|---|
| `project_id` | — | **Required.** Your GCP project ID |
| `region` | `us-central1` | GCP region for the cluster |
| `cluster_name` | `my-gke-cluster` | Name of the GKE cluster |
| `kubernetes_version` | `latest` | Kubernetes version |
| `vpc_name` | `gke-vpc` | VPC network name |
| `subnet_name` | `gke-subnet` | Subnet name for nodes |
| `subnet_cidr` | `10.0.0.0/20` | Node subnet CIDR |
| `pods_cidr` | `10.48.0.0/14` | Pod IP range |
| `services_cidr` | `10.52.0.0/20` | Service IP range |
| `master_cidr` | `172.16.0.0/28` | Control plane CIDR (must be /28) |
| `authorized_networks` | `0.0.0.0/0` | IPs allowed to reach the API server |
| `system_pool_machine_type` | `e2-medium` | Machine type for system nodes |
| `system_pool_min_nodes` | `1` | Min nodes per zone (system pool) |
| `system_pool_max_nodes` | `3` | Max nodes per zone (system pool) |
| `workload_pool_machine_type` | `e2-standard-4` | Machine type for workload nodes |
| `workload_pool_min_nodes` | `1` | Min nodes per zone (workload pool) |
| `workload_pool_max_nodes` | `5` | Max nodes per zone (workload pool) |

## Security highlights

**Private cluster** — nodes have no public IPs. All outbound traffic goes through Cloud NAT.

**Workload Identity** — pods authenticate to GCP APIs as GCP service accounts directly,
no key files needed. Enabled at both cluster and node pool level.

**Shielded nodes** — secure boot and integrity monitoring enabled on all nodes.

**Network policy** — Calico is enabled so you can write `NetworkPolicy` resources
to control pod-to-pod traffic.

**Authorized networks** — restrict `authorized_networks` to your office or VPN IP
in production. The default `0.0.0.0/0` is for dev only.

## Node pool design

Two pools with different purposes and taints:

```
system-pool   (e2-medium)
└── taint: node-role=system:NoSchedule
    └── only pods with matching toleration land here
    └── runs: CoreDNS, kube-proxy, monitoring agents

workload-pool  (e2-standard-4)
└── no taint — all application pods run here
└── autoscales 1→5 nodes per zone
```

To schedule a pod on the system pool, add this toleration:

```yaml
tolerations:
  - key: "node-role"
    value: "system"
    effect: "NoSchedule"
```

## Outputs

```sh
terraform output
```

| Output | Description |
|---|---|
| `cluster_name` | GKE cluster name |
| `cluster_endpoint` | Kubernetes API server endpoint |
| `region` | GCP region |
| `vpc_name` | VPC network name |
| `service_account_email` | GKE node service account email |

## Estimated cost

| Resource | Approximate monthly cost |
|---|---|
| GKE cluster management fee | ~$73 (waived for Autopilot) |
| e2-medium × 1 (system pool) | ~$27 |
| e2-standard-4 × 1 (workload pool) | ~$97 |
| **Minimum total** | **~$197/month** |

Costs vary by region. Always run `terraform plan` before applying.

## Teardown

```sh
terraform destroy
```

> Note: If you have PersistentVolumes or load balancers created outside Terraform
> (by your applications), delete those first or they will block the destroy.

## File structure

```
gcp-gke/
├── providers.tf              — google provider + required versions
├── versions.tf               — Terraform version constraint
├── variables.tf              — all input variables with descriptions
├── terraform.tfvars.example  — copy this to terraform.tfvars and fill in values
├── network.tf                — VPC, subnet, secondary ranges, Cloud NAT
├── main.tf                   — GKE cluster, system node pool, workload node pool
├── iam.tf                    — service account + IAM role bindings
└── outputs.tf                — cluster name, endpoint, service account
```
