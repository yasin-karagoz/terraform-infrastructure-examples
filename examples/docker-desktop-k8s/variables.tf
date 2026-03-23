variable "namespace" {
  description = "Kubernetes namespace for all resources"
  type        = string
  default     = "demo"
}

variable "app_name" {
  description = "Base name used across resources"
  type        = string
  default     = "webapp"
}

variable "app_image" {
  description = "Container image for the web application"
  type        = string
  default     = "nginx:1.25-alpine"
}

variable "app_replicas" {
  description = "Number of pod replicas"
  type        = number
  default     = 2
}

variable "app_port" {
  description = "Port the container listens on"
  type        = number
  default     = 80
}

variable "node_port" {
  description = "NodePort exposed on the host (30000-32767). Set to 0 to let Kubernetes assign one."
  type        = number
  default     = 30080
}

variable "pvc_storage_size" {
  description = "Storage size requested by the PersistentVolumeClaim"
  type        = string
  default     = "1Gi"
}

variable "labels" {
  description = "Common labels applied to every resource"
  type        = map(string)
  default = {
    managed-by  = "terraform"
    environment = "local"
  }
}
