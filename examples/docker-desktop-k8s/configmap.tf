# ─────────────────────────────────────────────
# ConfigMap — inject runtime configuration into pods
# ─────────────────────────────────────────────
resource "kubernetes_config_map" "app_config" {
  metadata {
    name      = "${var.app_name}-config"
    namespace = kubernetes_namespace.demo.metadata[0].name
    labels    = merge(var.labels, { app = var.app_name })
  }

  data = {
    # Example: override the default nginx welcome page
    "index.html" = <<-HTML
      <!DOCTYPE html>
      <html>
        <head><title>Terraform + Docker Desktop K8s</title></head>
        <body>
          <h1>Hello from Terraform!</h1>
          <p>Running on Docker Desktop Kubernetes.</p>
        </body>
      </html>
    HTML

    APP_ENV  = "local"
    LOG_LEVEL = "debug"
  }
}
