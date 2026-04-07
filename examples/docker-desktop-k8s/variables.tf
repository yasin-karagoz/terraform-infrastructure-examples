variable "namespace" {
  description = "Kubernetes namespace for all resources"
  type        = string
  default     = "demo"

  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]*[a-z0-9])?$", var.namespace))
    error_message = "namespace must be a valid Kubernetes name: lowercase alphanumeric characters or hyphens, must start and end with alphanumeric."
  }
}

variable "app_name" {
  description = "Base name used across resources"
  type        = string
  default     = "webapp"

  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]*[a-z0-9])?$", var.app_name))
    error_message = "app_name must be a valid Kubernetes name: lowercase alphanumeric characters or hyphens, must start and end with alphanumeric."
  }
}

variable "app_image" {
  description = "Container image for the web application"
  type        = string
  default     = "nginx:1.25-alpine"

  validation {
    condition     = can(regex("^[^:]+:.+$", var.app_image))
    error_message = "app_image must include an explicit tag (e.g. nginx:1.25-alpine). Using 'latest' is discouraged in production."
  }
}

variable "app_replicas" {
  description = "Number of pod replicas"
  type        = number
  default     = 2

  validation {
    condition     = var.app_replicas >= 1
    error_message = "app_replicas must be at least 1."
  }

  validation {
    condition     = var.app_replicas <= 50
    error_message = "app_replicas must not exceed 50 for a local cluster."
  }
}

variable "app_port" {
  description = "Port the container listens on"
  type        = number
  default     = 80

  validation {
    condition     = var.app_port >= 1 && var.app_port <= 65535
    error_message = "app_port must be a valid port number between 1 and 65535."
  }
}

variable "node_port" {
  description = "NodePort exposed on the host (30000-32767)."
  type        = number
  default     = 30080

  validation {
    condition     = var.node_port >= 30000 && var.node_port <= 32767
    error_message = "node_port must be in the Kubernetes NodePort range: 30000-32767."
  }
}

variable "pvc_storage_size" {
  description = "Storage size requested by the PersistentVolumeClaim"
  type        = string
  default     = "1Gi"

  validation {
    condition     = can(regex("^[0-9]+(Mi|Gi|Ti)$", var.pvc_storage_size))
    error_message = "pvc_storage_size must be a valid Kubernetes quantity using Mi, Gi, or Ti suffix (e.g. 512Mi, 1Gi, 2Ti)."
  }
}

variable "labels" {
  description = "Common labels applied to every resource"
  type        = map(string)
  default = {
    managed-by  = "terraform"
    environment = "local"
  }

  validation {
    condition     = contains(keys(var.labels), "managed-by")
    error_message = "labels must include a 'managed-by' key."
  }
}
