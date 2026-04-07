# unit_resources.tftest.hcl
#
# Tests that every resource is configured with the correct attributes.
# Uses mock_provider so no live Kubernetes cluster is required.
#
# Requires: Terraform >= 1.7
# Run with: terraform test

mock_provider "kubernetes" {}

# ─────────────────────────────────────────────────────────────────────────────
# Namespace
# ─────────────────────────────────────────────────────────────────────────────

run "namespace_name_matches_variable" {
  assert {
    condition     = kubernetes_namespace.demo.metadata[0].name == var.namespace
    error_message = "Namespace name must equal var.namespace ('${var.namespace}')"
  }
}

run "namespace_carries_managed_by_label" {
  assert {
    condition     = kubernetes_namespace.demo.metadata[0].labels["managed-by"] == "terraform"
    error_message = "Namespace is missing the 'managed-by=terraform' label"
  }
}

run "namespace_carries_name_label" {
  assert {
    condition     = kubernetes_namespace.demo.metadata[0].labels["name"] == var.namespace
    error_message = "Namespace 'name' label must equal var.namespace"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# ConfigMap
# ─────────────────────────────────────────────────────────────────────────────

run "configmap_name_includes_app_name" {
  assert {
    condition     = kubernetes_config_map.app_config.metadata[0].name == "${var.app_name}-config"
    error_message = "ConfigMap name must be '<app_name>-config', got: ${kubernetes_config_map.app_config.metadata[0].name}"
  }
}

run "configmap_in_correct_namespace" {
  assert {
    condition     = kubernetes_config_map.app_config.metadata[0].namespace == var.namespace
    error_message = "ConfigMap namespace must match var.namespace"
  }
}

run "configmap_has_app_env_key" {
  assert {
    condition     = contains(keys(kubernetes_config_map.app_config.data), "APP_ENV")
    error_message = "ConfigMap must contain the 'APP_ENV' key"
  }
}

run "configmap_has_log_level_key" {
  assert {
    condition     = contains(keys(kubernetes_config_map.app_config.data), "LOG_LEVEL")
    error_message = "ConfigMap must contain the 'LOG_LEVEL' key"
  }
}

run "configmap_has_index_html_key" {
  assert {
    condition     = contains(keys(kubernetes_config_map.app_config.data), "index.html")
    error_message = "ConfigMap must contain the 'index.html' key"
  }
}

run "configmap_app_env_value_is_local" {
  assert {
    condition     = kubernetes_config_map.app_config.data["APP_ENV"] == "local"
    error_message = "ConfigMap APP_ENV must be 'local'"
  }
}

run "configmap_log_level_value_is_debug" {
  assert {
    condition     = kubernetes_config_map.app_config.data["LOG_LEVEL"] == "debug"
    error_message = "ConfigMap LOG_LEVEL must be 'debug'"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# PersistentVolumeClaim
# ─────────────────────────────────────────────────────────────────────────────

run "pvc_name_includes_app_name" {
  assert {
    condition     = kubernetes_persistent_volume_claim.app_data.metadata[0].name == "${var.app_name}-data"
    error_message = "PVC name must be '<app_name>-data'"
  }
}

run "pvc_in_correct_namespace" {
  assert {
    condition     = kubernetes_persistent_volume_claim.app_data.metadata[0].namespace == var.namespace
    error_message = "PVC namespace must match var.namespace"
  }
}

run "pvc_access_mode_is_read_write_once" {
  assert {
    condition     = kubernetes_persistent_volume_claim.app_data.spec[0].access_modes[0] == "ReadWriteOnce"
    error_message = "PVC access mode must be 'ReadWriteOnce'"
  }
}

run "pvc_storage_request_matches_variable" {
  assert {
    condition     = kubernetes_persistent_volume_claim.app_data.spec[0].resources[0].requests["storage"] == var.pvc_storage_size
    error_message = "PVC storage request must equal var.pvc_storage_size ('${var.pvc_storage_size}')"
  }
}

run "pvc_custom_storage_size_flows_through" {
  variables {
    pvc_storage_size = "5Gi"
  }

  assert {
    condition     = kubernetes_persistent_volume_claim.app_data.spec[0].resources[0].requests["storage"] == "5Gi"
    error_message = "Custom PVC storage size '5Gi' did not flow through to the resource"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Deployment
# ─────────────────────────────────────────────────────────────────────────────

run "deployment_name_matches_app_name" {
  assert {
    condition     = kubernetes_deployment.app.metadata[0].name == var.app_name
    error_message = "Deployment name must equal var.app_name"
  }
}

run "deployment_in_correct_namespace" {
  assert {
    condition     = kubernetes_deployment.app.metadata[0].namespace == var.namespace
    error_message = "Deployment namespace must match var.namespace"
  }
}

run "deployment_replicas_match_variable" {
  assert {
    condition     = kubernetes_deployment.app.spec[0].replicas == var.app_replicas
    error_message = "Deployment replicas must equal var.app_replicas (${var.app_replicas})"
  }
}

run "deployment_custom_replicas_flow_through" {
  variables {
    app_replicas = 4
  }

  assert {
    condition     = kubernetes_deployment.app.spec[0].replicas == 4
    error_message = "Custom replica count 4 did not flow through to the Deployment"
  }
}

run "deployment_strategy_is_rolling_update" {
  assert {
    condition     = kubernetes_deployment.app.spec[0].strategy[0].type == "RollingUpdate"
    error_message = "Deployment strategy must be 'RollingUpdate'"
  }
}

run "deployment_rolling_update_max_unavailable_is_zero" {
  assert {
    condition     = kubernetes_deployment.app.spec[0].strategy[0].rolling_update[0].max_unavailable == "0"
    error_message = "RollingUpdate max_unavailable must be '0' to prevent downtime"
  }
}

run "deployment_container_image_matches_variable" {
  assert {
    condition     = kubernetes_deployment.app.spec[0].template[0].spec[0].container[0].image == var.app_image
    error_message = "Container image must equal var.app_image ('${var.app_image}')"
  }
}

run "deployment_container_name_matches_app_name" {
  assert {
    condition     = kubernetes_deployment.app.spec[0].template[0].spec[0].container[0].name == var.app_name
    error_message = "Container name must equal var.app_name"
  }
}

run "deployment_container_port_matches_variable" {
  assert {
    condition     = kubernetes_deployment.app.spec[0].template[0].spec[0].container[0].port[0].container_port == var.app_port
    error_message = "Container port must equal var.app_port (${var.app_port})"
  }
}

run "deployment_has_html_volume_mount" {
  assert {
    condition = anytrue([
      for vm in kubernetes_deployment.app.spec[0].template[0].spec[0].container[0].volume_mount :
      vm.name == "html" && vm.mount_path == "/usr/share/nginx/html"
    ])
    error_message = "Container must mount the 'html' volume at /usr/share/nginx/html"
  }
}

run "deployment_has_app_data_volume_mount" {
  assert {
    condition = anytrue([
      for vm in kubernetes_deployment.app.spec[0].template[0].spec[0].container[0].volume_mount :
      vm.name == "app-data" && vm.mount_path == "/data"
    ])
    error_message = "Container must mount the 'app-data' volume at /data"
  }
}

run "deployment_has_liveness_probe" {
  assert {
    condition     = length(kubernetes_deployment.app.spec[0].template[0].spec[0].container[0].liveness_probe) > 0
    error_message = "Deployment container must define a liveness probe"
  }
}

run "deployment_has_readiness_probe" {
  assert {
    condition     = length(kubernetes_deployment.app.spec[0].template[0].spec[0].container[0].readiness_probe) > 0
    error_message = "Deployment container must define a readiness probe"
  }
}

run "deployment_pod_label_matches_app_name" {
  assert {
    condition     = kubernetes_deployment.app.spec[0].template[0].metadata[0].labels["app"] == var.app_name
    error_message = "Pod template label 'app' must equal var.app_name"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Services
# ─────────────────────────────────────────────────────────────────────────────

run "nodeport_service_name_includes_app_name" {
  assert {
    condition     = kubernetes_service.app.metadata[0].name == "${var.app_name}-svc"
    error_message = "NodePort service name must be '<app_name>-svc'"
  }
}

run "nodeport_service_type_is_nodeport" {
  assert {
    condition     = kubernetes_service.app.spec[0].type == "NodePort"
    error_message = "External service type must be 'NodePort'"
  }
}

run "nodeport_service_node_port_matches_variable" {
  assert {
    condition     = kubernetes_service.app.spec[0].port[0].node_port == var.node_port
    error_message = "NodePort service node_port must equal var.node_port (${var.node_port})"
  }
}

run "nodeport_service_target_port_matches_app_port" {
  assert {
    condition     = kubernetes_service.app.spec[0].port[0].target_port == tostring(var.app_port)
    error_message = "NodePort service target_port must equal var.app_port"
  }
}

run "nodeport_service_selector_targets_app" {
  assert {
    condition     = kubernetes_service.app.spec[0].selector["app"] == var.app_name
    error_message = "NodePort service selector must target pods with label app=<app_name>"
  }
}

run "clusterip_service_name_includes_app_name" {
  assert {
    condition     = kubernetes_service.app_internal.metadata[0].name == "${var.app_name}-internal"
    error_message = "ClusterIP service name must be '<app_name>-internal'"
  }
}

run "clusterip_service_type_is_clusterip" {
  assert {
    condition     = kubernetes_service.app_internal.spec[0].type == "ClusterIP"
    error_message = "Internal service type must be 'ClusterIP'"
  }
}

run "clusterip_service_port_is_80" {
  assert {
    condition     = kubernetes_service.app_internal.spec[0].port[0].port == 80
    error_message = "ClusterIP service port must be 80"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Ingress
# ─────────────────────────────────────────────────────────────────────────────

run "ingress_name_includes_app_name" {
  assert {
    condition     = kubernetes_ingress_v1.app.metadata[0].name == "${var.app_name}-ingress"
    error_message = "Ingress name must be '<app_name>-ingress'"
  }
}

run "ingress_in_correct_namespace" {
  assert {
    condition     = kubernetes_ingress_v1.app.metadata[0].namespace == var.namespace
    error_message = "Ingress namespace must match var.namespace"
  }
}

run "ingress_class_is_nginx" {
  assert {
    condition     = kubernetes_ingress_v1.app.spec[0].ingress_class_name == "nginx"
    error_message = "Ingress class must be 'nginx'"
  }
}

run "ingress_rule_host_is_localhost" {
  assert {
    condition     = kubernetes_ingress_v1.app.spec[0].rule[0].host == "localhost"
    error_message = "Ingress rule host must be 'localhost'"
  }
}

run "ingress_backend_targets_internal_service" {
  assert {
    condition     = kubernetes_ingress_v1.app.spec[0].rule[0].http[0].path[0].backend[0].service[0].name == "${var.app_name}-internal"
    error_message = "Ingress backend must target the ClusterIP service '<app_name>-internal'"
  }
}

run "ingress_path_type_is_prefix" {
  assert {
    condition     = kubernetes_ingress_v1.app.spec[0].rule[0].http[0].path[0].path_type == "Prefix"
    error_message = "Ingress path type must be 'Prefix'"
  }
}

run "ingress_has_rewrite_annotation" {
  assert {
    condition     = contains(keys(kubernetes_ingress_v1.app.metadata[0].annotations), "nginx.ingress.kubernetes.io/rewrite-target")
    error_message = "Ingress must have the nginx rewrite-target annotation"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Cross-resource: namespace propagation
# ─────────────────────────────────────────────────────────────────────────────

run "all_resources_share_same_namespace" {
  variables {
    namespace = "production"
  }

  assert {
    condition     = kubernetes_namespace.demo.metadata[0].name == "production"
    error_message = "Namespace resource did not pick up custom namespace"
  }

  assert {
    condition     = kubernetes_deployment.app.metadata[0].namespace == "production"
    error_message = "Deployment is not in the custom namespace"
  }

  assert {
    condition     = kubernetes_service.app.metadata[0].namespace == "production"
    error_message = "NodePort service is not in the custom namespace"
  }

  assert {
    condition     = kubernetes_service.app_internal.metadata[0].namespace == "production"
    error_message = "ClusterIP service is not in the custom namespace"
  }

  assert {
    condition     = kubernetes_config_map.app_config.metadata[0].namespace == "production"
    error_message = "ConfigMap is not in the custom namespace"
  }

  assert {
    condition     = kubernetes_persistent_volume_claim.app_data.metadata[0].namespace == "production"
    error_message = "PVC is not in the custom namespace"
  }

  assert {
    condition     = kubernetes_ingress_v1.app.metadata[0].namespace == "production"
    error_message = "Ingress is not in the custom namespace"
  }
}
