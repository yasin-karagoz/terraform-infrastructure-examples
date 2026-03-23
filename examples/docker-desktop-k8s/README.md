# Example — Docker Desktop Kubernetes

Deploy a web application to your local Kubernetes cluster using Terraform.
No cloud account needed — runs entirely on Docker Desktop.

## What this example deploys

| Resource | Description |
|---|---|
| Namespace | `demo` — isolated space for all resources |
| Deployment | 2 replicas of nginx serving a custom HTML page |
| Service (ClusterIP) | Internal service for pod-to-pod traffic |
| Service (NodePort) | Exposes the app on `localhost:30080` |
| Ingress | Routes `http://localhost/` to the app (requires nginx-ingress) |
| ConfigMap | App config (env vars + custom index.html) |
| PersistentVolumeClaim | 1Gi volume mounted at `/data` in each pod |

## Prerequisites

- Docker Desktop with Kubernetes enabled
  - Open Docker Desktop → Settings → Kubernetes → Enable Kubernetes
  - Wait for the green indicator before continuing
- Terraform `>= 1.3.0`

```sh
brew install terraform kubectl
```

## Quick start

```sh
cd examples/docker-desktop-k8s

terraform init
terraform apply
```

Open your browser at `http://localhost:30080` — the app is running.

## Enable Ingress (optional)

To access the app at `http://localhost` instead of `localhost:30080`,
install the nginx ingress controller first:

```sh
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.10.0/deploy/static/provider/cloud/deploy.yaml

# Wait for it to be ready
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s
```

Then re-apply Terraform:

```sh
terraform apply
```

Now open `http://localhost` — nginx-ingress routes traffic to the app.

## Variables

All variables have sensible defaults. Override them in a `terraform.tfvars` file:

```hcl
# terraform.tfvars
namespace    = "demo"
app_name     = "webapp"
app_image    = "nginx:1.25-alpine"
app_replicas = 2
app_port     = 80
node_port    = 30080
pvc_storage_size = "1Gi"
```

| Variable | Default | Description |
|---|---|---|
| `namespace` | `demo` | Kubernetes namespace |
| `app_name` | `webapp` | Name used across all resources |
| `app_image` | `nginx:1.25-alpine` | Container image |
| `app_replicas` | `2` | Number of pod replicas |
| `app_port` | `80` | Port the container listens on |
| `node_port` | `30080` | Host port (NodePort service) |
| `pvc_storage_size` | `1Gi` | Persistent volume size |

## Verify the deployment

```sh
# Check pods are running
kubectl get pods -n demo

# Check services
kubectl get svc -n demo

# Check ingress
kubectl get ingress -n demo

# View app config
kubectl get configmap -n demo -o yaml

# Check persistent volume
kubectl get pvc -n demo
```

Expected output:
```
NAME                    READY   STATUS    RESTARTS   AGE
webapp-xxxxxxxxx-xxxxx  1/1     Running   0          1m
webapp-xxxxxxxxx-xxxxx  1/1     Running   0          1m
```

## Outputs

After `terraform apply` completes:

| Output | Description |
|---|---|
| `app_url` | URL to access the app via NodePort |
| `namespace` | Namespace where resources are deployed |
| `deployment_name` | Name of the Kubernetes Deployment |

```sh
terraform output
```

## Teardown

```sh
terraform destroy
```

This removes all resources — namespace, deployment, services, ingress, ConfigMap and PVC.

## File structure

```
docker-desktop-k8s/
├── main.tf         — provider config (connects to docker-desktop context)
├── variables.tf    — input variables with defaults
├── namespace.tf    — Kubernetes namespace
├── deployment.tf   — Deployment with probes, resource limits, volume mounts
├── service.tf      — ClusterIP + NodePort services
├── ingress.tf      — Ingress rule for localhost
├── configmap.tf    — App environment config + custom index.html
├── pvc.tf          — PersistentVolumeClaim for /data
└── outputs.tf      — app_url, namespace, deployment_name
```
