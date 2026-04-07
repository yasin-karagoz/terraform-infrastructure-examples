# unit_validations.tftest.hcl
#
# Tests that variable validation blocks REJECT invalid inputs.
# Uses `expect_failures` — the run passes only if Terraform raises the
# specified validation error. If the invalid value is silently accepted,
# the test fails.
#
# Pattern: negative testing / guard-rail verification.
# Requires: Terraform >= 1.7
# Run with: terraform test

mock_provider "kubernetes" {}

# ─────────────────────────────────────────────────────────────────────────────
# node_port — must be 30000-32767
# ─────────────────────────────────────────────────────────────────────────────

run "reject_node_port_below_range" {
  variables {
    node_port = 8080
  }

  expect_failures = [var.node_port]
}

run "reject_node_port_above_range" {
  variables {
    node_port = 40000
  }

  expect_failures = [var.node_port]
}

run "reject_node_port_at_zero" {
  variables {
    node_port = 0
  }

  expect_failures = [var.node_port]
}

run "accept_node_port_at_lower_bound" {
  variables {
    node_port = 30000
  }

  assert {
    condition     = var.node_port == 30000
    error_message = "node_port 30000 (lower bound) should be accepted"
  }
}

run "accept_node_port_at_upper_bound" {
  variables {
    node_port = 32767
  }

  assert {
    condition     = var.node_port == 32767
    error_message = "node_port 32767 (upper bound) should be accepted"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# app_replicas — must be >= 1 and <= 50
# ─────────────────────────────────────────────────────────────────────────────

run "reject_zero_replicas" {
  variables {
    app_replicas = 0
  }

  expect_failures = [var.app_replicas]
}

run "reject_negative_replicas" {
  variables {
    app_replicas = -1
  }

  expect_failures = [var.app_replicas]
}

run "reject_replicas_exceeding_max" {
  variables {
    app_replicas = 51
  }

  expect_failures = [var.app_replicas]
}

run "accept_single_replica" {
  variables {
    app_replicas = 1
  }

  assert {
    condition     = var.app_replicas == 1
    error_message = "app_replicas = 1 (minimum) should be accepted"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# namespace — must match Kubernetes naming rules
# ─────────────────────────────────────────────────────────────────────────────

run "reject_namespace_with_uppercase" {
  variables {
    namespace = "MyNamespace"
  }

  expect_failures = [var.namespace]
}

run "reject_namespace_with_underscore" {
  variables {
    namespace = "my_namespace"
  }

  expect_failures = [var.namespace]
}

run "reject_namespace_starting_with_hyphen" {
  variables {
    namespace = "-myns"
  }

  expect_failures = [var.namespace]
}

run "reject_namespace_ending_with_hyphen" {
  variables {
    namespace = "myns-"
  }

  expect_failures = [var.namespace]
}

run "accept_valid_namespace_with_hyphens" {
  variables {
    namespace = "my-app-staging"
  }

  assert {
    condition     = var.namespace == "my-app-staging"
    error_message = "Valid hyphenated namespace should be accepted"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# app_name — same Kubernetes naming rules as namespace
# ─────────────────────────────────────────────────────────────────────────────

run "reject_app_name_with_uppercase" {
  variables {
    app_name = "WebApp"
  }

  expect_failures = [var.app_name]
}

run "reject_app_name_with_spaces" {
  variables {
    app_name = "my app"
  }

  expect_failures = [var.app_name]
}

# ─────────────────────────────────────────────────────────────────────────────
# app_image — must include an explicit tag
# ─────────────────────────────────────────────────────────────────────────────

run "reject_image_without_tag" {
  variables {
    app_image = "nginx"
  }

  expect_failures = [var.app_image]
}

run "accept_image_with_explicit_tag" {
  variables {
    app_image = "nginx:1.26-alpine"
  }

  assert {
    condition     = var.app_image == "nginx:1.26-alpine"
    error_message = "Image with explicit tag should be accepted"
  }
}

run "accept_image_with_digest" {
  variables {
    app_image = "nginx:sha256-abc123"
  }

  assert {
    condition     = startswith(var.app_image, "nginx:")
    error_message = "Image with digest-style tag should be accepted"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# pvc_storage_size — must use Mi, Gi, or Ti suffix
# ─────────────────────────────────────────────────────────────────────────────

run "reject_pvc_size_with_kb_suffix" {
  variables {
    pvc_storage_size = "1024Ki"
  }

  expect_failures = [var.pvc_storage_size]
}

run "reject_pvc_size_with_tb_suffix" {
  variables {
    pvc_storage_size = "1TB"
  }

  expect_failures = [var.pvc_storage_size]
}

run "reject_pvc_size_plain_number" {
  variables {
    pvc_storage_size = "512"
  }

  expect_failures = [var.pvc_storage_size]
}

run "accept_pvc_size_in_mi" {
  variables {
    pvc_storage_size = "512Mi"
  }

  assert {
    condition     = var.pvc_storage_size == "512Mi"
    error_message = "PVC size in Mi should be accepted"
  }
}

run "accept_pvc_size_in_gi" {
  variables {
    pvc_storage_size = "10Gi"
  }

  assert {
    condition     = var.pvc_storage_size == "10Gi"
    error_message = "PVC size in Gi should be accepted"
  }
}

run "accept_pvc_size_in_ti" {
  variables {
    pvc_storage_size = "2Ti"
  }

  assert {
    condition     = var.pvc_storage_size == "2Ti"
    error_message = "PVC size in Ti should be accepted"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# app_port — must be 1-65535
# ─────────────────────────────────────────────────────────────────────────────

run "reject_port_zero" {
  variables {
    app_port = 0
  }

  expect_failures = [var.app_port]
}

run "reject_port_above_max" {
  variables {
    app_port = 65536
  }

  expect_failures = [var.app_port]
}

# ─────────────────────────────────────────────────────────────────────────────
# labels — must include managed-by key
# ─────────────────────────────────────────────────────────────────────────────

run "reject_labels_missing_managed_by" {
  variables {
    labels = {
      environment = "test"
      team        = "platform"
    }
  }

  expect_failures = [var.labels]
}

run "accept_labels_with_managed_by" {
  variables {
    labels = {
      managed-by  = "terraform"
      environment = "test"
    }
  }

  assert {
    condition     = var.labels["managed-by"] == "terraform"
    error_message = "Labels with managed-by key should be accepted"
  }
}
