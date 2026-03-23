output "namespace" {
  description = "Kubernetes namespace where resources are deployed"
  value       = kubernetes_namespace.demo.metadata[0].name
}

output "deployment_name" {
  description = "Name of the Deployment"
  value       = kubernetes_deployment.app.metadata[0].name
}

output "nodeport_url" {
  description = "URL to reach the app via NodePort (Docker Desktop maps this to localhost)"
  value       = "http://localhost:${var.node_port}"
}

output "ingress_url" {
  description = "URL to reach the app via Ingress (requires nginx-ingress controller)"
  value       = "http://localhost/"
}

output "configmap_name" {
  description = "Name of the ConfigMap"
  value       = kubernetes_config_map.app_config.metadata[0].name
}

output "pvc_name" {
  description = "Name of the PersistentVolumeClaim"
  value       = kubernetes_persistent_volume_claim.app_data.metadata[0].name
}
