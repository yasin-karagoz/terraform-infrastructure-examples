# unit_outputs.tftest.hcl
#
# Tests that every output value is correctly computed from its inputs.
#
# Requires: Terraform >= 1.7
# Run with: terraform test

mock_provider "kubernetes" {}

# ─────────────────────────────────────────────────────────────────────────────
# namespace output
# ─────────────────────────────────────────────────────────────────────────────

run "output_namespace_equals_variable" {
  assert {
    condition     = output.namespace == var.namespace
    error_message = "Output 'namespace' must equal var.namespace ('${var.namespace}')"
  }
}

run "output_namespace_custom_value" {
  variables {
    namespace = "my-app"
  }

  assert {
    condition     = output.namespace == "my-app"
    error_message = "Output 'namespace' must reflect the custom namespace 'my-app'"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# deployment_name output
# ─────────────────────────────────────────────────────────────────────────────

run "output_deployment_name_equals_app_name" {
  assert {
    condition     = output.deployment_name == var.app_name
    error_message = "Output 'deployment_name' must equal var.app_name ('${var.app_name}')"
  }
}

run "output_deployment_name_custom_app_name" {
  variables {
    app_name = "api-server"
  }

  assert {
    condition     = output.deployment_name == "api-server"
    error_message = "Output 'deployment_name' must reflect the custom app_name 'api-server'"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# nodeport_url output
# ─────────────────────────────────────────────────────────────────────────────

run "output_nodeport_url_default" {
  assert {
    condition     = output.nodeport_url == "http://localhost:30080"
    error_message = "Default nodeport_url must be 'http://localhost:30080', got: ${output.nodeport_url}"
  }
}

run "output_nodeport_url_custom_port" {
  variables {
    node_port = 31500
  }

  assert {
    condition     = output.nodeport_url == "http://localhost:31500"
    error_message = "nodeport_url must embed the custom node_port, got: ${output.nodeport_url}"
  }
}

run "output_nodeport_url_starts_with_http" {
  assert {
    condition     = startswith(output.nodeport_url, "http://")
    error_message = "nodeport_url must start with 'http://'"
  }
}

run "output_nodeport_url_contains_localhost" {
  assert {
    condition     = can(regex("localhost", output.nodeport_url))
    error_message = "nodeport_url must target localhost"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# ingress_url output
# ─────────────────────────────────────────────────────────────────────────────

run "output_ingress_url_is_localhost_root" {
  assert {
    condition     = output.ingress_url == "http://localhost/"
    error_message = "ingress_url must be 'http://localhost/', got: ${output.ingress_url}"
  }
}

run "output_ingress_url_starts_with_http" {
  assert {
    condition     = startswith(output.ingress_url, "http://")
    error_message = "ingress_url must start with 'http://'"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# configmap_name output
# ─────────────────────────────────────────────────────────────────────────────

run "output_configmap_name_default" {
  assert {
    condition     = output.configmap_name == "webapp-config"
    error_message = "Default configmap_name must be 'webapp-config', got: ${output.configmap_name}"
  }
}

run "output_configmap_name_custom_app_name" {
  variables {
    app_name = "backend"
  }

  assert {
    condition     = output.configmap_name == "backend-config"
    error_message = "configmap_name must reflect the custom app_name, got: ${output.configmap_name}"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# pvc_name output
# ─────────────────────────────────────────────────────────────────────────────

run "output_pvc_name_default" {
  assert {
    condition     = output.pvc_name == "webapp-data"
    error_message = "Default pvc_name must be 'webapp-data', got: ${output.pvc_name}"
  }
}

run "output_pvc_name_custom_app_name" {
  variables {
    app_name = "worker"
  }

  assert {
    condition     = output.pvc_name == "worker-data"
    error_message = "pvc_name must reflect the custom app_name, got: ${output.pvc_name}"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Combined: all name outputs consistently use the same app_name
# ─────────────────────────────────────────────────────────────────────────────

run "all_name_outputs_consistent_with_app_name" {
  variables {
    app_name = "myservice"
  }

  assert {
    condition     = output.deployment_name == "myservice"
    error_message = "deployment_name must be 'myservice'"
  }

  assert {
    condition     = output.configmap_name == "myservice-config"
    error_message = "configmap_name must be 'myservice-config'"
  }

  assert {
    condition     = output.pvc_name == "myservice-data"
    error_message = "pvc_name must be 'myservice-data'"
  }
}
