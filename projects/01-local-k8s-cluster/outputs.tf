output "cluster_name" {
  description = "Name of the Kind cluster"
  value       = kind_cluster.this.name
}

output "kubeconfig_path" {
  description = "Path to the kubeconfig file for the Kind cluster"
  value       = kind_cluster.this.kubeconfig_path
}

output "kubeconfig" {
  description = "Kubeconfig content for the Kind cluster"
  value       = kind_cluster.this.kubeconfig
  sensitive   = true
}

output "registry_url" {
  description = "Local Docker registry URL (push images here)"
  value       = "localhost:${var.registry_port}"
}

output "registry_container_name" {
  description = "Name of the local registry Docker container"
  value       = docker_container.registry.name
}
