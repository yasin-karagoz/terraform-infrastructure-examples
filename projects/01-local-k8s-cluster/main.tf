terraform {
  required_providers {
    kind = {
      source  = "tehcyx/kind"
      version = "~> 0.4.0"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.27"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
  required_version = ">= 1.5.0"
}

provider "kind" {}

provider "docker" {}

provider "kubernetes" {
  config_path = kind_cluster.this.kubeconfig_path
}

# Local Docker registry
resource "docker_container" "registry" {
  name  = var.registry_name
  image = docker_image.registry.image_id

  restart = "always"

  ports {
    internal = 5000
    external = var.registry_port
  }
}

resource "docker_image" "registry" {
  name = "registry:2"
}

# Connect registry to the Kind network after cluster creation
resource "null_resource" "registry_kind_network" {
  provisioner "local-exec" {
    command = "docker network connect kind ${var.registry_name} || true"
  }

  depends_on = [kind_cluster.this, docker_container.registry]
}

# Kind cluster
resource "kind_cluster" "this" {
  name            = var.cluster_name
  node_image      = "kindest/node:${var.kubernetes_version}"
  wait_for_ready  = true

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    # Control plane node with port mappings for ingress
    node {
      role = "control-plane"

      kubeadm_config_patches = [
        <<-EOT
          kind: InitConfiguration
          nodeRegistration:
            kubeletExtraArgs:
              node-labels: "ingress-ready=true"
        EOT
      ]

      extra_port_mappings {
        container_port = 80
        host_port      = 80
        protocol       = "TCP"
      }

      extra_port_mappings {
        container_port = 443
        host_port      = 443
        protocol       = "TCP"
      }
    }

    dynamic "node" {
      for_each = range(var.worker_count)
      content {
        role = "worker"
      }
    }

    # Tell containerd in Kind nodes about the local registry
    containerd_config_patches = [
      <<-EOT
        [plugins."io.containerd.grpc.v1.cri".registry.mirrors."localhost:${var.registry_port}"]
          endpoint = ["http://${var.registry_name}:5000"]
      EOT
    ]
  }
}
