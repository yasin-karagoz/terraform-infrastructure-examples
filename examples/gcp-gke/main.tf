# Regional GKE Cluster — spans multiple zones for high availability
resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.region # use a zone (e.g. "us-central1-a") for zonal cluster

  # We manage node pools separately — remove the default one
  remove_default_node_pool = true
  initial_node_count       = 1

  network    = google_compute_network.vpc.id
  subnetwork = google_compute_subnetwork.gke_subnet.id

  min_master_version = var.kubernetes_version

  # --- Private Cluster ---
  # Nodes have no public IPs; they reach the internet through Cloud NAT
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false # set true to also hide the control plane
    master_ipv4_cidr_block  = var.master_cidr
  }

  # Control which external IPs can reach the API server
  master_authorized_networks_config {
    dynamic "cidr_blocks" {
      for_each = var.authorized_networks
      content {
        cidr_block   = cidr_blocks.value.cidr_block
        display_name = cidr_blocks.value.display_name
      }
    }
  }

  # --- Networking ---
  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  # Enable VPC-native networking (required for private clusters)
  networking_mode = "VPC_NATIVE"

  # --- Security ---
  # Workload Identity: lets pods authenticate as GCP service accounts
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # Shielded nodes for supply-chain security
  enable_shielded_nodes = true

  # Enable network policy (Calico) for pod-level firewall rules
  network_policy {
    enabled  = true
    provider = "CALICO"
  }

  addons_config {
    # Required when network_policy is enabled
    network_policy_config {
      disabled = false
    }

    # Horizontal Pod Autoscaler
    horizontal_pod_autoscaling {
      disabled = false
    }

    # HTTP load balancing for GKE Ingress
    http_load_balancing {
      disabled = false
    }

    # GKE Managed Prometheus (Google Cloud Managed Service for Prometheus)
    gke_backup_agent_config {
      enabled = true
    }
  }

  # Automatically upgrade nodes and repair unhealthy nodes
  maintenance_policy {
    recurring_window {
      start_time = "2024-01-01T03:00:00Z" # 3am UTC
      end_time   = "2024-01-01T07:00:00Z"
      recurrence = "FREQ=WEEKLY;BYDAY=SA,SU"
    }
  }

  # Enable cluster-level logging and monitoring to Google Cloud
  logging_config {
    enable_components = ["SYSTEM_COMPONENTS", "WORKLOADS"]
  }

  monitoring_config {
    enable_components = ["SYSTEM_COMPONENTS"]

    managed_prometheus {
      enabled = true
    }
  }

  resource_labels = var.labels

  lifecycle {
    ignore_changes = [
      # Ignore changes to initial_node_count after creation
      initial_node_count,
    ]
  }
}

# --- System Node Pool ---
# Runs system workloads: CoreDNS, kube-proxy, monitoring agents, etc.
resource "google_container_node_pool" "system" {
  name     = "system-pool"
  cluster  = google_container_cluster.primary.id
  location = var.region

  # Autoscaling per zone
  autoscaling {
    min_node_count = var.system_pool_min_nodes
    max_node_count = var.system_pool_max_nodes
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
  }

  node_config {
    machine_type = var.system_pool_machine_type
    disk_size_gb = var.system_pool_disk_size_gb
    disk_type    = "pd-standard"

    service_account = google_service_account.gke_node_sa.email

    # Only allow nodes to call GCP APIs they are scoped for
    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]

    # Shielded instance options
    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    # Workload Identity on node pool level
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    # Taint system nodes so only system pods (with toleration) run here
    taint {
      key    = "node-role"
      value  = "system"
      effect = "NO_SCHEDULE"
    }

    labels = merge(var.labels, {
      node-pool = "system"
    })

    metadata = {
      disable-legacy-endpoints = "true"
    }
  }
}

# --- Workload Node Pool ---
# Runs application workloads
resource "google_container_node_pool" "workload" {
  name     = "workload-pool"
  cluster  = google_container_cluster.primary.id
  location = var.region

  autoscaling {
    min_node_count = var.workload_pool_min_nodes
    max_node_count = var.workload_pool_max_nodes
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
  }

  node_config {
    machine_type = var.workload_pool_machine_type
    disk_size_gb = var.workload_pool_disk_size_gb
    disk_type    = "pd-ssd"

    service_account = google_service_account.gke_node_sa.email
    oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]

    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    labels = merge(var.labels, {
      node-pool = "workload"
    })

    metadata = {
      disable-legacy-endpoints = "true"
    }
  }
}
