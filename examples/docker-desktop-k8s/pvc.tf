# ─────────────────────────────────────────────
# PersistentVolumeClaim
# Docker Desktop ships with a default "hostpath" StorageClass that
# automatically provisions volumes, so no manual PV is needed.
# ─────────────────────────────────────────────
resource "kubernetes_persistent_volume_claim" "app_data" {
  metadata {
    name      = "${var.app_name}-data"
    namespace = kubernetes_namespace.demo.metadata[0].name
    labels    = merge(var.labels, { app = var.app_name })
  }

  spec {
    access_modes = ["ReadWriteOnce"]

    resources {
      requests = {
        storage = var.pvc_storage_size
      }
    }

    # Leave storage_class_name empty to use the cluster default (hostpath on Docker Desktop)
  }

  # Avoid Terraform trying to re-create the PVC when pods are using it
  wait_until_bound = false
}
