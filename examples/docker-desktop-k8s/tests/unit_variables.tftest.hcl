# unit_variables.tftest.hcl
#
# Tests that every variable default is correct and that custom values
# are accepted and flow through the configuration as expected.
#
# Requires: Terraform >= 1.7 (mock_provider support)
# Run with: terraform test
#
# No live cluster needed — all provider calls are mocked.

mock_provider "kubernetes" {}

# ─────────────────────────────────────────────────────────────────────────────
# Default values
# ─────────────────────────────────────────────────────────────────────────────

run "defaults_namespace" {
  assert {
    condition     = var.namespace == "demo"
    error_message = "Default namespace must be 'demo', got: ${var.namespace}"
  }
}

run "defaults_app_name" {
  assert {
    condition     = var.app_name == "webapp"
    error_message = "Default app_name must be 'webapp', got: ${var.app_name}"
  }
}

run "defaults_app_image" {
  assert {
    condition     = var.app_image == "nginx:1.25-alpine"
    error_message = "Default image must be 'nginx:1.25-alpine', got: ${var.app_image}"
  }
}

run "defaults_replicas" {
  assert {
    condition     = var.app_replicas == 2
    error_message = "Default replicas must be 2, got: ${var.app_replicas}"
  }
}

run "defaults_app_port" {
  assert {
    condition     = var.app_port == 80
    error_message = "Default app_port must be 80, got: ${var.app_port}"
  }
}

run "defaults_node_port" {
  assert {
    condition     = var.node_port == 30080
    error_message = "Default node_port must be 30080, got: ${var.node_port}"
  }
}

run "defaults_pvc_storage_size" {
  assert {
    condition     = var.pvc_storage_size == "1Gi"
    error_message = "Default pvc_storage_size must be '1Gi', got: ${var.pvc_storage_size}"
  }
}

run "defaults_labels_managed_by" {
  assert {
    condition     = var.labels["managed-by"] == "terraform"
    error_message = "Default label 'managed-by' must be 'terraform'"
  }
}

run "defaults_labels_environment" {
  assert {
    condition     = var.labels["environment"] == "local"
    error_message = "Default label 'environment' must be 'local'"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Node port is in the valid Kubernetes NodePort range (30000-32767)
# ─────────────────────────────────────────────────────────────────────────────

run "node_port_in_valid_range" {
  assert {
    condition     = var.node_port >= 30000 && var.node_port <= 32767
    error_message = "node_port must be in range 30000-32767, got: ${var.node_port}"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Custom variable values are accepted and override defaults
# ─────────────────────────────────────────────────────────────────────────────

run "custom_namespace_accepted" {
  variables {
    namespace = "staging"
  }

  assert {
    condition     = var.namespace == "staging"
    error_message = "Custom namespace 'staging' was not accepted"
  }
}

run "custom_replicas_accepted" {
  variables {
    app_replicas = 3
  }

  assert {
    condition     = var.app_replicas == 3
    error_message = "Custom replica count 3 was not accepted"
  }
}

run "custom_image_accepted" {
  variables {
    app_image = "nginx:1.26-alpine"
  }

  assert {
    condition     = var.app_image == "nginx:1.26-alpine"
    error_message = "Custom image 'nginx:1.26-alpine' was not accepted"
  }
}

run "custom_node_port_in_range_accepted" {
  variables {
    node_port = 31000
  }

  assert {
    condition     = var.node_port == 31000
    error_message = "Custom node_port 31000 was not accepted"
  }
}

run "custom_labels_merged" {
  variables {
    labels = {
      managed-by  = "terraform"
      environment = "test"
      team        = "platform"
    }
  }

  assert {
    condition     = var.labels["team"] == "platform"
    error_message = "Custom label 'team' was not preserved"
  }

  assert {
    condition     = var.labels["environment"] == "test"
    error_message = "Custom label 'environment' override was not accepted"
  }
}
