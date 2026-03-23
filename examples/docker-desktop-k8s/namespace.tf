# ─────────────────────────────────────────────
# Namespace
# ─────────────────────────────────────────────
resource "kubernetes_namespace" "demo" {
  metadata {
    name   = var.namespace
    labels = merge(var.labels, { name = var.namespace })
  }
}
