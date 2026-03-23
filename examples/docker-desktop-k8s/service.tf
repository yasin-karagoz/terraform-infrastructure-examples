# ─────────────────────────────────────────────
# Service — NodePort (directly reachable on localhost via Docker Desktop)
# ─────────────────────────────────────────────
resource "kubernetes_service" "app" {
  metadata {
    name      = "${var.app_name}-svc"
    namespace = kubernetes_namespace.demo.metadata[0].name
    labels    = merge(var.labels, { app = var.app_name })
  }

  spec {
    type     = "NodePort"
    selector = { app = var.app_name }

    port {
      name        = "http"
      protocol    = "TCP"
      port        = 80
      target_port = var.app_port
      node_port   = var.node_port
    }
  }
}

# ─────────────────────────────────────────────
# ClusterIP Service — internal cluster communication example
# ─────────────────────────────────────────────
resource "kubernetes_service" "app_internal" {
  metadata {
    name      = "${var.app_name}-internal"
    namespace = kubernetes_namespace.demo.metadata[0].name
    labels    = merge(var.labels, { app = var.app_name })
  }

  spec {
    type     = "ClusterIP"
    selector = { app = var.app_name }

    port {
      name        = "http"
      protocol    = "TCP"
      port        = 80
      target_port = var.app_port
    }
  }
}
