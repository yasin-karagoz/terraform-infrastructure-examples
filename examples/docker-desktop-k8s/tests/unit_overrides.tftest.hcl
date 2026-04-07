# unit_overrides.tftest.hcl
#
# Tests using `override_resource` — injects controlled values for
# computed attributes (uid, resource_version, etc.) that a real provider
# would return after creation but a mock provider auto-generates randomly.
#
# Use this pattern when:
#   - You need to test logic that depends on computed/provider-assigned values
#   - You want deterministic IDs in assertions (e.g. for cross-resource refs)
#   - You want to simulate specific provider-returned states
#
# Requires: Terraform >= 1.7
# Run with: terraform test

mock_provider "kubernetes" {}

# ─────────────────────────────────────────────────────────────────────────────
# Override namespace — inject deterministic computed attributes
# ─────────────────────────────────────────────────────────────────────────────

run "override_namespace_uid" {
  override_resource {
    target = kubernetes_namespace.demo
    values = {
      metadata = [{
        name             = "demo"
        uid              = "aaaa-bbbb-cccc-dddd"
        resource_version = "1001"
        labels = {
          managed-by  = "terraform"
          environment = "local"
          name        = "demo"
        }
      }]
    }
  }

  assert {
    condition     = kubernetes_namespace.demo.metadata[0].uid == "aaaa-bbbb-cccc-dddd"
    error_message = "Overridden namespace UID must be 'aaaa-bbbb-cccc-dddd'"
  }

  assert {
    condition     = kubernetes_namespace.demo.metadata[0].resource_version == "1001"
    error_message = "Overridden namespace resource_version must be '1001'"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Override ConfigMap — verify downstream references use the correct name
# ─────────────────────────────────────────────────────────────────────────────

run "override_configmap_verifies_deployment_env_ref" {
  override_resource {
    target = kubernetes_config_map.app_config
    values = {
      metadata = [{
        name      = "webapp-config"
        namespace = "demo"
      }]
      data = {
        APP_ENV   = "local"
        LOG_LEVEL = "debug"
        "index.html" = "<html>test</html>"
      }
    }
  }

  # The deployment references the ConfigMap by name — verify the reference is correct
  assert {
    condition = (
      kubernetes_deployment.app.spec[0].template[0].spec[0].container[0].env[0].value_from[0].config_map_key_ref[0].name
      == kubernetes_config_map.app_config.metadata[0].name
    )
    error_message = "Deployment env var must reference the ConfigMap by its overridden name"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Override PVC — verify deployment volume claim reference is consistent
# ─────────────────────────────────────────────────────────────────────────────

run "override_pvc_verifies_deployment_volume_ref" {
  override_resource {
    target = kubernetes_persistent_volume_claim.app_data
    values = {
      metadata = [{
        name      = "webapp-data"
        namespace = "demo"
        uid       = "pvc-uid-1234"
      }]
      spec = [{
        access_modes = ["ReadWriteOnce"]
        resources = [{
          requests = { storage = "1Gi" }
        }]
      }]
    }
  }

  assert {
    condition = (
      kubernetes_deployment.app.spec[0].template[0].spec[0].volume[1].persistent_volume_claim[0].claim_name
      == kubernetes_persistent_volume_claim.app_data.metadata[0].name
    )
    error_message = "Deployment volume must reference the PVC by its overridden name"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Override internal service — verify ingress backend points at the right service
# ─────────────────────────────────────────────────────────────────────────────

run "override_service_verifies_ingress_backend" {
  override_resource {
    target = kubernetes_service.app_internal
    values = {
      metadata = [{
        name      = "webapp-internal"
        namespace = "demo"
      }]
      spec = [{
        type     = "ClusterIP"
        selector = { app = "webapp" }
        port = [{
          name        = "http"
          port        = 80
          target_port = "80"
          protocol    = "TCP"
        }]
      }]
    }
  }

  assert {
    condition = (
      kubernetes_ingress_v1.app.spec[0].rule[0].http[0].path[0].backend[0].service[0].name
      == kubernetes_service.app_internal.metadata[0].name
    )
    error_message = "Ingress backend must reference the overridden ClusterIP service name"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Override deployment — simulate a provider returning unexpected replica count
# (useful for testing what happens when drift exists)
# ─────────────────────────────────────────────────────────────────────────────

run "override_deployment_with_drifted_replicas" {
  variables {
    app_replicas = 2
  }

  # Simulate provider returning 1 replica (manual scale-down drift)
  override_resource {
    target = kubernetes_deployment.app
    values = {
      spec = [{
        replicas = 2  # Terraform desired state wins — still 2
      }]
    }
  }

  assert {
    condition     = kubernetes_deployment.app.spec[0].replicas == var.app_replicas
    error_message = "Terraform desired state (var.app_replicas) must take precedence over provider drift"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Override namespace + deployment together — multi-resource override
# ─────────────────────────────────────────────────────────────────────────────

run "multi_resource_override_namespace_and_deployment" {
  variables {
    namespace    = "blue"
    app_replicas = 3
  }

  override_resource {
    target = kubernetes_namespace.demo
    values = {
      metadata = [{
        name = "blue"
        uid  = "ns-uid-blue"
      }]
    }
  }

  override_resource {
    target = kubernetes_deployment.app
    values = {
      metadata = [{
        name      = "webapp"
        namespace = "blue"
        uid       = "deploy-uid-blue"
      }]
      spec = [{
        replicas = 3
      }]
    }
  }

  assert {
    condition     = kubernetes_namespace.demo.metadata[0].uid == "ns-uid-blue"
    error_message = "Namespace UID must be the overridden value"
  }

  assert {
    condition     = kubernetes_deployment.app.metadata[0].uid == "deploy-uid-blue"
    error_message = "Deployment UID must be the overridden value"
  }

  assert {
    condition     = kubernetes_deployment.app.spec[0].replicas == 3
    error_message = "Deployment replicas must match the variable value"
  }
}
