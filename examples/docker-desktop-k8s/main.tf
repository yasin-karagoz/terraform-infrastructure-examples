terraform {
  required_version = ">= 1.3.0"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.23.0"
    }
  }

  # Local backend — state stored on disk (suitable for local dev)
  backend "local" {
    path = "terraform.tfstate"
  }
}

# Docker Desktop exposes the local cluster via the "docker-desktop" context.
# Make sure Docker Desktop is running and Kubernetes is enabled before applying.
provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "docker-desktop"
}
