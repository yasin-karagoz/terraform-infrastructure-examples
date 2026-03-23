variable "cluster_name" {
  description = "Name of the Kind cluster"
  type        = string
  default     = "local-k8s"
}

variable "kubernetes_version" {
  description = "Kubernetes version to use for the Kind cluster (Kind node image tag)"
  type        = string
  default     = "v1.29.2"
}

variable "worker_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 2
}

variable "registry_name" {
  description = "Name of the local Docker registry container"
  type        = string
  default     = "local-registry"
}

variable "registry_port" {
  description = "Host port for the local Docker registry"
  type        = number
  default     = 5001
}
