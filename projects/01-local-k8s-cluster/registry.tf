# ConfigMap that tells the cluster about the local registry.
# This follows the KEP-1755 standard so tools like kubectl and skaffold
# can discover registries automatically.
resource "kubernetes_config_map" "local_registry_hosting" {
  metadata {
    name      = "local-registry-hosting"
    namespace = "kube-public"
  }

  data = {
    "localRegistryHosting.v1" = <<-EOT
      host: "localhost:${var.registry_port}"
      help: "https://kind.sigs.k8s.io/docs/user/local-registry/"
    EOT
  }

  depends_on = [kind_cluster.this]
}
