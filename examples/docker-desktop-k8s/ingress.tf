# ─────────────────────────────────────────────
# Ingress
#
# Requires an Ingress Controller installed in the cluster.
# Quick setup with nginx-ingress on Docker Desktop:
#
#   kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.10.0/deploy/static/provider/cloud/deploy.yaml
#
# After applying, the app will be reachable at http://localhost/
# ─────────────────────────────────────────────
resource "kubernetes_ingress_v1" "app" {
  metadata {
    name      = "${var.app_name}-ingress"
    namespace = kubernetes_namespace.demo.metadata[0].name
    labels    = merge(var.labels, { app = var.app_name })

    annotations = {
      "nginx.ingress.kubernetes.io/rewrite-target" = "/"
    }
  }

  spec {
    ingress_class_name = "nginx"

    rule {
      host = "localhost"

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service.app_internal.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}
