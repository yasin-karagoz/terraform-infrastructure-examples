# Local Projects Plan

Based on the bio: Staff SWE specializing in IaC gaps, Golang K8s operators, FinOps, self-service DB provisioning, GitHub Actions, Terraform, Helm, ArgoCD, GKE.

No cloud required. Every project runs on Docker Desktop Kubernetes or Kind.

---

## Repository Layout

```
terraform/
├── examples/
│   └── docker-desktop-k8s/       ✅ already done
├── projects/
│   ├── 01-local-k8s-cluster/     Kind + Terraform cluster bootstrap
│   ├── 02-platform-stack/        ArgoCD + nginx-ingress + cert-manager + Prometheus/Grafana via Helm + Terraform
│   ├── 03-db-provisioner/        Self-service DB operator (Go) + CRD + local MySQL/PostgreSQL/MongoDB
│   ├── 04-finops-operator/       Go operator that surfaces resource waste → Prometheus metrics → Grafana dashboard
│   ├── 05-helm-charts/           Custom Helm chart library (app, cronjob, worker templates)
│   └── 06-local-github-actions/  act runner setup + sample CI workflows for all projects above
└── Terraform.md
```

---

## Project 01 — Local Kubernetes Cluster (`kind` + Terraform)

**What:** Terraform provisions a multi-node Kind cluster (1 control-plane + 2 workers) with a pre-configured kubeconfig and a local container registry at `localhost:5001`.

**Why it maps to your bio:** You work on GKE — Kind gives you an identical API surface locally. Terraform manages the cluster the same way you'd manage a GKE cluster in code.

**Stack:** Terraform `tehcyx/kind` provider, Kind, Docker.

**Files to build:**
- `main.tf` — Kind cluster resource (1 control-plane, 2 workers, extraPortMappings for 80/443)
- `variables.tf` — cluster name, k8s version, node counts
- `registry.tf` — local Docker registry container wired into the Kind network
- `outputs.tf` — kubeconfig path, registry URL

**What you get after apply:**
```
kind-control-plane
kind-worker
kind-worker2
localhost:5001  ← push images here, Kind nodes pull from it
```

---

## Project 02 — Platform Stack (ArgoCD + Observability + Ingress)

**What:** Full GitOps + observability platform deployed with Terraform (`hashicorp/helm` + `hashicorp/kubernetes` providers) against the Kind cluster from Project 01.

**Why it maps to your bio:** Mirrors exactly what you run on GKE — ArgoCD, nginx-ingress, Prometheus/Grafana — but entirely local. You can demo your GitOps workflows without a cloud account.

**Stack:** Terraform Helm provider, ArgoCD, nginx-ingress, cert-manager (with a local CA), kube-prometheus-stack.

**Files to build:**
- `main.tf` — provider config pointing at Kind kubeconfig
- `argocd.tf` — ArgoCD Helm release + initial admin password (kubernetes_secret)
- `ingress.tf` — nginx-ingress Helm release with NodePort 80/443 mapped through Kind
- `cert_manager.tf` — cert-manager Helm release + `ClusterIssuer` for self-signed local CA
- `monitoring.tf` — kube-prometheus-stack Helm release (Prometheus + Grafana + Alertmanager)
- `argocd_apps.tf` — ArgoCD `Application` CRs pointing at your local Git repo (future projects deploy via this)
- `outputs.tf` — ArgoCD URL, Grafana URL, admin passwords

**What you get after apply:**
```
https://argocd.localhost    ArgoCD UI
https://grafana.localhost   Grafana (pre-wired datasource: Prometheus)
https://prometheus.localhost
```

---

## Project 03 — Self-Service Database Provisioning Operator (Go)

**What:** A production-style Golang Kubernetes operator. Developers create a `DatabaseRequest` CR → operator provisions a Helm-managed database (MySQL, PostgreSQL, MongoDB) → injects a connection secret into the requesting namespace.

**Why it maps to your bio:** This is your "open a PR, get a DB" system rebuilt locally. All the same patterns (CRD, reconciler, Helm lifecycle management, secret injection) but running in Kind so you can iterate on the operator code without touching prod.

**Stack:** Go, `controller-runtime`, `kubebuilder`, Helm Go SDK, MySQL/PostgreSQL/MongoDB Bitnami charts.

**Structure:**
```
projects/03-db-provisioner/
├── operator/                    Go module (kubebuilder scaffold)
│   ├── api/v1alpha1/
│   │   └── databaserequest_types.go   CRD spec: engine, version, storage, namespace
│   ├── controllers/
│   │   └── databaserequest_controller.go
│   │       - Watch DatabaseRequest CRs
│   │       - Install/upgrade Helm chart for requested engine
│   │       - Wait for StatefulSet ready
│   │       - Create connection Secret in requester's namespace
│   │       - Update CR status (phase: Pending → Provisioning → Ready)
│   ├── config/                  kustomize manifests (CRD, RBAC, Deployment)
│   └── Dockerfile               multi-stage Go build
├── terraform/
│   ├── main.tf                  deploy operator via Helm into Kind cluster
│   └── example_cr.tf            example DatabaseRequest resource (terraform apply creates it)
└── examples/
    ├── mysql-request.yaml
    ├── postgres-request.yaml
    └── mongodb-request.yaml
```

**Flow:**
```
kubectl apply -f postgres-request.yaml
# → operator sees CR
# → helm install bitnami/postgresql in target namespace
# → waits for pod Ready
# → creates Secret: postgres-myapp-credentials
# → CR status.phase = Ready
```

---

## Project 04 — FinOps Operator (Go)

**What:** A Golang operator that watches all Pods in the cluster, compares `resources.requests` vs actual usage (scraped from the Metrics API), and emits custom Prometheus metrics surfacing waste. A pre-built Grafana dashboard visualizes it.

**Why it maps to your bio:** Your FinOps work on AWS/GCP — this is the same pattern (operator that surfaces waste before it becomes a problem) running locally so you can show the concept in demos and interviews without needing a cloud bill.

**Stack:** Go, `controller-runtime`, `client-go` Metrics API, `prometheus/client_golang`, Grafana dashboard JSON.

**Structure:**
```
projects/04-finops-operator/
├── operator/
│   ├── controllers/
│   │   └── waste_controller.go
│   │       - Reconcile on Pod changes
│   │       - Fetch metrics-server data (CPU/mem actual vs requests)
│   │       - Emit Prometheus gauge: container_cpu_waste_ratio, container_memory_waste_ratio
│   │       - Annotate pods with waste score
│   ├── metrics/
│   │   └── server.go            expose /metrics on :8080
│   └── Dockerfile
├── terraform/
│   ├── main.tf                  deploy operator + metrics-server into Kind cluster
│   └── grafana_dashboard.tf     import dashboard JSON into Grafana via kubernetes_config_map
└── dashboards/
    └── finops-waste.json        Grafana dashboard: top wasteful pods, namespace rollup, trend over time
```

**Custom Prometheus metrics emitted:**
```
container_cpu_waste_ratio{namespace, pod, container}      # (request - actual) / request
container_memory_waste_ratio{namespace, pod, container}
namespace_monthly_waste_usd_estimate                      # applies $/core/hr and $/GB/hr constants
```

---

## Project 05 — Custom Helm Chart Library

**What:** A local Helm chart repository (served by ChartMuseum running in Kind) containing three reusable base charts your other projects consume:

| Chart | Purpose |
|---|---|
| `base-app` | Deployment + Service + Ingress + HPA + PodDisruptionBudget template |
| `base-cronjob` | CronJob with configurable schedule, image, env, secrets |
| `base-worker` | Deployment (no ingress) + KEDA ScaledObject for queue-based workers |

**Why it maps to your bio:** You already use Helm at work. This gives you a local chart library you own end-to-end — good for demos and as a starting point for any new project.

**Files to build:**
- `charts/base-app/` — full chart with sensible defaults (probes, resources, topology spread, RBAC)
- `charts/base-cronjob/` — parameterized CronJob with retries and history limits
- `charts/base-worker/` — worker with optional KEDA autoscaling
- `terraform/chartmuseum.tf` — deploy ChartMuseum into Kind, push charts on apply via `null_resource` + `helm push`
- `terraform/test_release.tf` — deploy a test release from each chart to verify

---

## Project 06 — Local GitHub Actions with `act`

**What:** A Dockerfile-based `act` runner environment + GitHub Actions workflow files that CI-test all five projects above on every `git push` — without leaving your laptop.

**Why it maps to your bio:** You live in GitHub Actions. `act` lets you run your workflows locally so you catch pipeline bugs before they waste time in the actual CI.

**Stack:** `act` (nektos/act), Docker, Make.

**Files to build:**
```
projects/06-local-github-actions/
├── .actrc                       default flags (--platform ubuntu-latest=...)
├── runner/
│   └── Dockerfile               custom act runner image: terraform + kubectl + helm + go + kind
├── .github/workflows/
│   ├── 01-kind-cluster.yml      terraform init/plan/apply project 01
│   ├── 02-platform-stack.yml    terraform init/plan project 02
│   ├── 03-db-operator.yml       go build + go test + docker build for operator
│   ├── 04-finops-operator.yml   go build + go test + docker build for operator
│   └── 05-helm-charts.yml       helm lint + helm unittest for all charts
└── Makefile                     `make ci` runs all workflows via act in sequence
```

---

## Implementation Order

| # | Project | Builds on |
|---|---|---|
| 1 | `01-local-k8s-cluster` | nothing — start here |
| 2 | `02-platform-stack` | 01 (needs a running cluster) |
| 3 | `05-helm-charts` | 02 (ChartMuseum deployed there) |
| 4 | `03-db-provisioner` | 01 + 02 (ArgoCD can deploy it) |
| 5 | `04-finops-operator` | 01 + 02 (needs Prometheus from platform stack) |
| 6 | `06-local-github-actions` | all of the above |

---

## Prerequisites (one-time laptop setup)

```sh
# Kubernetes tooling
brew install kind kubectl helm

# Terraform
brew install terraform

# Go (for operators)
brew install go

# act (local GitHub Actions)
brew install act

# kubebuilder (scaffolds Go operators)
brew install kubebuilder
```

---

## What this repo becomes

A fully self-contained, cloud-free engineering portfolio that demonstrates:
- IaC lifecycle management (Terraform)
- GitOps (ArgoCD)
- Golang operator development (kubebuilder + controller-runtime)
- FinOps / cost observability (custom metrics + Grafana)
- Self-service platform tooling (DB provisioner)
- CI/CD (GitHub Actions + act)

Everything someone would ask about in a Staff SWE interview — runnable on a laptop.
