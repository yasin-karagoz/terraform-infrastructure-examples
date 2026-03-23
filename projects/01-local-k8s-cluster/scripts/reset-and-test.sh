#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────
# reset-and-test.sh
# Destroys and recreates the local Kind cluster
# from scratch, then runs smoke tests.
# Use this before recording a video to prove
# the tutorial is fully reproducible.
# ─────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
KUBECONFIG_PATH="$PROJECT_DIR/local-k8s-config"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

pass() { echo -e "${GREEN}✔ $1${NC}"; }
fail() { echo -e "${RED}✘ $1${NC}"; exit 1; }
info() { echo -e "${YELLOW}▶ $1${NC}"; }

cd "$PROJECT_DIR"

# ── Prerequisites ─────────────────────────────
info "Checking prerequisites..."
command -v terraform >/dev/null || fail "terraform not found"
command -v kind      >/dev/null || fail "kind not found"
command -v kubectl   >/dev/null || fail "kubectl not found"
command -v docker    >/dev/null || fail "docker not found"
docker info >/dev/null 2>&1    || fail "Docker daemon is not running"
pass "All prerequisites met"

# ── Destroy existing state ────────────────────
info "Destroying existing cluster..."
terraform destroy -auto-approve 2>&1 | tail -5
pass "Destroy complete"

# ── Fresh apply ───────────────────────────────
info "Applying from scratch..."
terraform apply -auto-approve 2>&1 | tail -10
pass "Apply complete"

export KUBECONFIG="$KUBECONFIG_PATH"

# ── Smoke tests ───────────────────────────────
info "Running smoke tests..."

# 1. All 3 nodes must be Ready
info "Test 1: Nodes ready"
for i in $(seq 1 12); do
  READY=$(kubectl get nodes --no-headers 2>/dev/null | grep -c "Ready" || true)
  if [ "$READY" -eq 3 ]; then break; fi
  echo "  Waiting for nodes ($READY/3 ready)... attempt $i/12"
  sleep 5
done
[ "$(kubectl get nodes --no-headers | grep -c "Ready")" -eq 3 ] || fail "Not all nodes are Ready"
pass "Test 1 passed: 3/3 nodes Ready"

# 2. Control plane must have ingress-ready label
info "Test 2: ingress-ready label on control-plane"
kubectl get node local-k8s-control-plane -o jsonpath='{.metadata.labels.ingress-ready}' | grep -q "true" \
  || fail "Control plane missing ingress-ready=true label"
pass "Test 2 passed: ingress-ready=true label present"

# 3. Local registry container must be running
info "Test 3: Local registry container running"
docker ps --filter "name=local-registry" --filter "status=running" | grep -q "local-registry" \
  || fail "local-registry container is not running"
pass "Test 3 passed: local-registry container running"

# 4. Registry reachable on localhost:5001
info "Test 4: Registry reachable on localhost:5001"
curl -sf http://localhost:5001/v2/ >/dev/null \
  || fail "Registry not reachable at localhost:5001"
pass "Test 4 passed: registry responds at localhost:5001"

# 5. Registry connected to Kind network
info "Test 5: Registry on Kind Docker network"
docker inspect local-registry --format '{{range $k,$v := .NetworkSettings.Networks}}{{$k}} {{end}}' \
  | grep -q "kind" || fail "local-registry is not connected to Kind network"
pass "Test 5 passed: registry is on Kind network"

# 6. ConfigMap exists in kube-public
info "Test 6: local-registry-hosting ConfigMap present"
kubectl get configmap local-registry-hosting -n kube-public >/dev/null 2>&1 \
  || fail "local-registry-hosting ConfigMap not found in kube-public"
pass "Test 6 passed: local-registry-hosting ConfigMap exists"

# 7. Push and pull a test image through the registry
info "Test 7: Push and pull image via local registry"
docker pull busybox:latest >/dev/null 2>&1
docker tag busybox:latest localhost:5001/test-busybox:latest
docker push localhost:5001/test-busybox:latest >/dev/null 2>&1
docker rmi localhost:5001/test-busybox:latest >/dev/null 2>&1
pass "Test 7 passed: image push/pull to local registry works"

# ── Summary ───────────────────────────────────
echo ""
echo -e "${GREEN}═══════════════════════════════════════${NC}"
echo -e "${GREEN}  All tests passed — ready to record!  ${NC}"
echo -e "${GREEN}═══════════════════════════════════════${NC}"
echo ""
echo "  Cluster : $(kubectl config current-context)"
echo "  Registry: $(terraform output -raw registry_url)"
echo "  Nodes   :"
kubectl get nodes --no-headers | awk '{printf "    %-35s %s\n", $1, $2}'
echo ""
echo "  To use the cluster:"
echo "  export KUBECONFIG=$KUBECONFIG_PATH"
