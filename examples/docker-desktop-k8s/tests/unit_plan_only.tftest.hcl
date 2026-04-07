# unit_plan_only.tftest.hcl
#
# Tests using `command = plan` — Terraform evaluates the configuration and
# produces a plan but does NOT create any resources. Ideal for:
#   - Fast feedback in CI (no apply cost)
#   - Verifying the plan is coherent before a full apply
#   - Asserting on planned values without side effects
#
# Key difference from default (apply) runs:
#   - Resources are not actually created
#   - Computed attributes (id, resource_version, uid) are unknown
#   - Only attributes you explicitly set are available for assertions
#
# Requires: Terraform >= 1.7
# Run with: terraform test

mock_provider "kubernetes" {}

# ─────────────────────────────────────────────────────────────────────────────
# Smoke tests — plan succeeds (no assertion needed; error = test failure)
# ─────────────────────────────────────────────────────────────────────────────

run "plan_succeeds_with_all_defaults" {
  command = plan
}

run "plan_succeeds_with_custom_namespace" {
  command = plan

  variables {
    namespace = "staging"
  }
}

run "plan_succeeds_with_minimal_resources" {
  command = plan

  variables {
    namespace    = "test"
    app_name     = "api"
    app_replicas = 1
    node_port    = 30090
  }
}

run "plan_succeeds_with_high_replicas" {
  command = plan

  variables {
    app_replicas = 10
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Assert on planned resource attributes
# ─────────────────────────────────────────────────────────────────────────────

run "plan_namespace_resource_name" {
  command = plan

  variables {
    namespace = "preview"
  }

  assert {
    condition     = kubernetes_namespace.demo.metadata[0].name == "preview"
    error_message = "Planned namespace name must equal the custom namespace variable"
  }
}

run "plan_deployment_replica_count" {
  command = plan

  variables {
    app_replicas = 3
  }

  assert {
    condition     = kubernetes_deployment.app.spec[0].replicas == 3
    error_message = "Planned deployment should have 3 replicas"
  }
}

run "plan_deployment_uses_custom_image" {
  command = plan

  variables {
    app_image = "nginx:1.26-alpine"
  }

  assert {
    condition     = kubernetes_deployment.app.spec[0].template[0].spec[0].container[0].image == "nginx:1.26-alpine"
    error_message = "Planned container image must reflect the custom app_image variable"
  }
}

run "plan_nodeport_service_port" {
  command = plan

  variables {
    node_port = 31234
  }

  assert {
    condition     = kubernetes_service.app.spec[0].port[0].node_port == 31234
    error_message = "Planned NodePort must be 31234"
  }
}

run "plan_configmap_data_keys_present" {
  command = plan

  assert {
    condition = alltrue([
      contains(keys(kubernetes_config_map.app_config.data), "APP_ENV"),
      contains(keys(kubernetes_config_map.app_config.data), "LOG_LEVEL"),
      contains(keys(kubernetes_config_map.app_config.data), "index.html"),
    ])
    error_message = "Planned ConfigMap must contain APP_ENV, LOG_LEVEL, and index.html keys"
  }
}

run "plan_pvc_storage_size" {
  command = plan

  variables {
    pvc_storage_size = "5Gi"
  }

  assert {
    condition     = kubernetes_persistent_volume_claim.app_data.spec[0].resources[0].requests["storage"] == "5Gi"
    error_message = "Planned PVC must request 5Gi of storage"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Assert on planned outputs
# ─────────────────────────────────────────────────────────────────────────────

run "plan_output_namespace" {
  command = plan

  variables {
    namespace = "canary"
  }

  assert {
    condition     = output.namespace == "canary"
    error_message = "Planned output 'namespace' must be 'canary'"
  }
}

run "plan_output_nodeport_url_format" {
  command = plan

  variables {
    node_port = 30500
  }

  assert {
    condition     = output.nodeport_url == "http://localhost:30500"
    error_message = "Planned nodeport_url must be 'http://localhost:30500'"
  }
}

run "plan_output_configmap_name_format" {
  command = plan

  variables {
    app_name = "frontend"
  }

  assert {
    condition     = output.configmap_name == "frontend-config"
    error_message = "Planned configmap_name output must be 'frontend-config'"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Plan-only: verify rolling update strategy is preserved across var changes
# ─────────────────────────────────────────────────────────────────────────────

run "plan_rolling_update_strategy_unaffected_by_replica_change" {
  command = plan

  variables {
    app_replicas = 10
  }

  assert {
    condition     = kubernetes_deployment.app.spec[0].strategy[0].type == "RollingUpdate"
    error_message = "RollingUpdate strategy must be preserved regardless of replica count"
  }

  assert {
    condition     = kubernetes_deployment.app.spec[0].strategy[0].rolling_update[0].max_unavailable == "0"
    error_message = "max_unavailable must stay '0' regardless of replica count"
  }
}
