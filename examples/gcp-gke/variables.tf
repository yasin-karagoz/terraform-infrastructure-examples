variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region for the cluster"
  type        = string
  default     = "us-central1"
}

variable "cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
  default     = "my-gke-cluster"
}

variable "kubernetes_version" {
  description = "Kubernetes version for the cluster (use 'latest' or a specific version)"
  type        = string
  default     = "latest"
}

# --- Networking ---
variable "vpc_name" {
  description = "Name of the VPC network"
  type        = string
  default     = "gke-vpc"
}

variable "subnet_name" {
  description = "Name of the subnet for GKE nodes"
  type        = string
  default     = "gke-subnet"
}

variable "subnet_cidr" {
  description = "CIDR range for the GKE node subnet"
  type        = string
  default     = "10.0.0.0/20"
}

variable "pods_cidr" {
  description = "Secondary CIDR range for pods"
  type        = string
  default     = "10.48.0.0/14"
}

variable "services_cidr" {
  description = "Secondary CIDR range for services"
  type        = string
  default     = "10.52.0.0/20"
}

variable "master_cidr" {
  description = "CIDR for the GKE control plane (must be /28)"
  type        = string
  default     = "172.16.0.0/28"
}

variable "authorized_networks" {
  description = "CIDR blocks authorized to access the cluster API server"
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = [
    {
      cidr_block   = "0.0.0.0/0"
      display_name = "all (restrict this in production)"
    }
  ]
}

# --- System Node Pool ---
variable "system_pool_machine_type" {
  description = "Machine type for the system node pool"
  type        = string
  default     = "e2-medium"
}

variable "system_pool_min_nodes" {
  description = "Minimum nodes per zone in the system pool"
  type        = number
  default     = 1
}

variable "system_pool_max_nodes" {
  description = "Maximum nodes per zone in the system pool"
  type        = number
  default     = 3
}

variable "system_pool_disk_size_gb" {
  description = "Disk size in GB for system pool nodes"
  type        = number
  default     = 50
}

# --- Workload Node Pool ---
variable "workload_pool_machine_type" {
  description = "Machine type for the workload node pool"
  type        = string
  default     = "e2-standard-4"
}

variable "workload_pool_min_nodes" {
  description = "Minimum nodes per zone in the workload pool"
  type        = number
  default     = 1
}

variable "workload_pool_max_nodes" {
  description = "Maximum nodes per zone in the workload pool"
  type        = number
  default     = 5
}

variable "workload_pool_disk_size_gb" {
  description = "Disk size in GB for workload pool nodes"
  type        = number
  default     = 100
}

variable "labels" {
  description = "Labels to apply to GCP resources"
  type        = map(string)
  default = {
    environment = "dev"
    managed-by  = "terraform"
  }
}
