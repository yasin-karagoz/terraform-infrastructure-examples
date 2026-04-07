# unit_chained_runs.tftest.hcl
#
# Tests using chained `run` blocks — state is preserved between runs within
# the same file, so each run builds on the previous one.
#
# This pattern tests:
#   - Initial apply produces the expected state
#   - In-place updates (e.g. scale replicas, swap image) produce correct diffs
#   - Values that should NOT change across an update remain stable
#   - Final state after multiple changes is coherent
#
# Run order in a file is always top-to-bottom. State accumulates.
#
# Requires: Terraform >= 1.7
# Run with: terraform test

mock_provider "kubernetes" {}

# ─────────────────────────────────────────────────────────────────────────────
# Chain 1: Initial deploy → scale up → scale down
# ─────────────────────────────────────────────────────────────────────────────

run "chain1_initial_deploy" {
  # Default: 2 replicas
  assert {
    condition     = kubernetes_deployment.app.spec[0].replicas == 2
    error_message = "Initial deploy must have 2 replicas"
  }

  assert {
    condition     = kubernetes_deployment.app.spec[0].template[0].spec[0].container[0].image == "nginx:1.25-alpine"
    error_message = "Initial deploy must use the default image"
  }
}

run "chain1_scale_up" {
  variables {
    app_replicas = 5
  }

  assert {
    condition     = kubernetes_deployment.app.spec[0].replicas == 5
    error_message = "After scale-up, replicas must be 5"
  }

  # Image must not change during a replica-only update
  assert {
    condition     = kubernetes_deployment.app.spec[0].template[0].spec[0].container[0].image == "nginx:1.25-alpine"
    error_message = "Scale-up must not change the container image"
  }
}

run "chain1_scale_down" {
  variables {
    app_replicas = 1
  }

  assert {
    condition     = kubernetes_deployment.app.spec[0].replicas == 1
    error_message = "After scale-down, replicas must be 1"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Chain 2: Initial deploy → image update → combined update
# ─────────────────────────────────────────────────────────────────────────────

run "chain2_initial_deploy" {
  variables {
    app_name     = "chain2app"
    app_replicas = 2
    app_image    = "nginx:1.25-alpine"
    node_port    = 30082
  }

  assert {
    condition     = kubernetes_deployment.app.spec[0].template[0].spec[0].container[0].image == "nginx:1.25-alpine"
    error_message = "Initial image must be nginx:1.25-alpine"
  }

  assert {
    condition     = kubernetes_deployment.app.metadata[0].name == "chain2app"
    error_message = "Deployment name must be 'chain2app'"
  }
}

run "chain2_image_update" {
  variables {
    app_name     = "chain2app"
    app_replicas = 2
    app_image    = "nginx:1.26-alpine"
    node_port    = 30082
  }

  assert {
    condition     = kubernetes_deployment.app.spec[0].template[0].spec[0].container[0].image == "nginx:1.26-alpine"
    error_message = "After image update, container must use nginx:1.26-alpine"
  }

  # Replicas must be unaffected by the image update
  assert {
    condition     = kubernetes_deployment.app.spec[0].replicas == 2
    error_message = "Image update must not change replica count"
  }

  # Deployment name must be stable across the image update
  assert {
    condition     = kubernetes_deployment.app.metadata[0].name == "chain2app"
    error_message = "Deployment name must remain 'chain2app' after image update"
  }
}

run "chain2_combined_scale_and_image" {
  variables {
    app_name     = "chain2app"
    app_replicas = 4
    app_image    = "nginx:1.27-alpine"
    node_port    = 30082
  }

  assert {
    condition     = kubernetes_deployment.app.spec[0].replicas == 4
    error_message = "Combined update: replicas must be 4"
  }

  assert {
    condition     = kubernetes_deployment.app.spec[0].template[0].spec[0].container[0].image == "nginx:1.27-alpine"
    error_message = "Combined update: image must be nginx:1.27-alpine"
  }

  assert {
    condition     = kubernetes_service.app.spec[0].port[0].node_port == 30082
    error_message = "NodePort must remain 30082 throughout the chain"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Chain 3: Namespace rename propagates to all child resources
# ─────────────────────────────────────────────────────────────────────────────

run "chain3_initial_namespace" {
  variables {
    namespace = "blue"
    node_port = 30083
  }

  assert {
    condition     = kubernetes_namespace.demo.metadata[0].name == "blue"
    error_message = "Initial namespace must be 'blue'"
  }

  assert {
    condition     = kubernetes_deployment.app.metadata[0].namespace == "blue"
    error_message = "Deployment must be in namespace 'blue'"
  }

  assert {
    condition     = kubernetes_service.app.metadata[0].namespace == "blue"
    error_message = "NodePort service must be in namespace 'blue'"
  }
}

run "chain3_rename_namespace" {
  variables {
    namespace = "green"
    node_port = 30083
  }

  assert {
    condition     = kubernetes_namespace.demo.metadata[0].name == "green"
    error_message = "After rename, namespace must be 'green'"
  }

  assert {
    condition     = kubernetes_deployment.app.metadata[0].namespace == "green"
    error_message = "After rename, deployment must be in namespace 'green'"
  }

  assert {
    condition     = kubernetes_config_map.app_config.metadata[0].namespace == "green"
    error_message = "After rename, ConfigMap must be in namespace 'green'"
  }

  assert {
    condition     = kubernetes_persistent_volume_claim.app_data.metadata[0].namespace == "green"
    error_message = "After rename, PVC must be in namespace 'green'"
  }

  assert {
    condition     = kubernetes_ingress_v1.app.metadata[0].namespace == "green"
    error_message = "After rename, Ingress must be in namespace 'green'"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Chain 4: Storage size increase (PVC resize)
# ─────────────────────────────────────────────────────────────────────────────

run "chain4_initial_pvc_size" {
  variables {
    pvc_storage_size = "1Gi"
    node_port        = 30084
  }

  assert {
    condition     = kubernetes_persistent_volume_claim.app_data.spec[0].resources[0].requests["storage"] == "1Gi"
    error_message = "Initial PVC size must be 1Gi"
  }
}

run "chain4_increase_pvc_size" {
  variables {
    pvc_storage_size = "10Gi"
    node_port        = 30084
  }

  assert {
    condition     = kubernetes_persistent_volume_claim.app_data.spec[0].resources[0].requests["storage"] == "10Gi"
    error_message = "After resize, PVC must request 10Gi"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Chain 5: Label updates propagate to all resources
# ─────────────────────────────────────────────────────────────────────────────

run "chain5_initial_labels" {
  variables {
    node_port = 30085
    labels = {
      managed-by  = "terraform"
      environment = "dev"
    }
  }

  assert {
    condition     = kubernetes_deployment.app.metadata[0].labels["environment"] == "dev"
    error_message = "Initial deployment label 'environment' must be 'dev'"
  }
}

run "chain5_update_environment_label" {
  variables {
    node_port = 30085
    labels = {
      managed-by  = "terraform"
      environment = "staging"
      version     = "v2"
    }
  }

  assert {
    condition     = kubernetes_deployment.app.metadata[0].labels["environment"] == "staging"
    error_message = "After label update, deployment label 'environment' must be 'staging'"
  }

  assert {
    condition     = kubernetes_service.app.metadata[0].labels["environment"] == "staging"
    error_message = "After label update, service label 'environment' must be 'staging'"
  }

  assert {
    condition     = kubernetes_config_map.app_config.metadata[0].labels["environment"] == "staging"
    error_message = "After label update, ConfigMap label 'environment' must be 'staging'"
  }
}
