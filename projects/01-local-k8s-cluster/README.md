# Project 01 — Local Kubernetes Cluster

Provisions a multi-node [Kind](https://kind.sigs.k8s.io/) cluster with a local Docker registry using Terraform.

## What you get

```
kind-local-k8s-control-plane   ← ingress-ready, port 80/443 mapped to host
kind-local-k8s-worker
kind-local-k8s-worker2
localhost:5001                  ← local Docker registry (push images here)
```

## Prerequisites

```sh
brew install kind terraform kubectl
```

Docker Desktop must be running.

## Usage

```sh
cd projects/01-local-k8s-cluster

terraform init
terraform apply

# Export kubeconfig
export KUBECONFIG=$(terraform output -raw kubeconfig_path)

# Verify cluster
kubectl get nodes

# Push an image to the local registry
docker build -t localhost:5001/my-app:latest .
docker push localhost:5001/my-app:latest
```

## Variables

| Name | Default | Description |
|---|---|---|
| `cluster_name` | `local-k8s` | Kind cluster name |
| `kubernetes_version` | `v1.29.2` | K8s node image tag |
| `worker_count` | `2` | Number of worker nodes |
| `registry_name` | `local-registry` | Registry container name |
| `registry_port` | `5001` | Host port for the registry |

## Outputs

| Name | Description |
|---|---|
| `kubeconfig_path` | Path to the kubeconfig file |
| `registry_url` | Local registry URL (`localhost:5001`) |

## Teardown

```sh
terraform destroy
```
