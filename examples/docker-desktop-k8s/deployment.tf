# ─────────────────────────────────────────────
# Deployment
# ─────────────────────────────────────────────
resource "kubernetes_deployment" "app" {
  metadata {
    name      = var.app_name
    namespace = kubernetes_namespace.demo.metadata[0].name
    labels    = merge(var.labels, { app = var.app_name })
  }

  spec {
    replicas = var.app_replicas

    selector {
      match_labels = { app = var.app_name }
    }

    # Rolling-update strategy — safe default for local dev
    strategy {
      type = "RollingUpdate"
      rolling_update {
        max_surge       = "1"
        max_unavailable = "0"
      }
    }

    template {
      metadata {
        labels = merge(var.labels, { app = var.app_name })
      }

      spec {
        container {
          name  = var.app_name
          image = var.app_image

          port {
            container_port = var.app_port
          }

          # Expose ConfigMap keys as environment variables
          env {
            name = "APP_ENV"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map.app_config.metadata[0].name
                key  = "APP_ENV"
              }
            }
          }

          env {
            name = "LOG_LEVEL"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map.app_config.metadata[0].name
                key  = "LOG_LEVEL"
              }
            }
          }

          # Mount the custom HTML from ConfigMap into nginx's web root
          volume_mount {
            name       = "html"
            mount_path = "/usr/share/nginx/html"
          }

          # Mount the PVC for persistent application data
          volume_mount {
            name       = "app-data"
            mount_path = "/data"
          }

          resources {
            requests = {
              cpu    = "50m"
              memory = "64Mi"
            }
            limits = {
              cpu    = "250m"
              memory = "128Mi"
            }
          }

          liveness_probe {
            http_get {
              path = "/"
              port = var.app_port
            }
            initial_delay_seconds = 5
            period_seconds        = 10
          }

          readiness_probe {
            http_get {
              path = "/"
              port = var.app_port
            }
            initial_delay_seconds = 3
            period_seconds        = 5
          }
        }

        # ConfigMap volume — serves the custom index.html
        volume {
          name = "html"
          config_map {
            name = kubernetes_config_map.app_config.metadata[0].name
            items {
              key  = "index.html"
              path = "index.html"
            }
          }
        }

        # PVC volume — persistent storage
        volume {
          name = "app-data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.app_data.metadata[0].name
          }
        }
      }
    }
  }

  depends_on = [kubernetes_namespace.demo]
}
