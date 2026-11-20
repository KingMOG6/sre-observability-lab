#!/usr/bin/env bash
# Run after a reboot: brings the lab back to a known state.
docker start sre-control-plane >/dev/null 2>&1 || true
kind export kubeconfig --name sre
kubectl config use-context kind-sre
echo "Waiting for the node..."
kubectl wait --for=condition=Ready node --all --timeout=180s
echo "Waiting for the shop and monitoring pods..."
kubectl wait --for=condition=Available deployment --all -n shop --timeout=300s
kubectl wait --for=condition=Available deployment --all -n monitoring --timeout=300s
kubectl get pods -n shop
kubectl get pods -n monitoring
free -h | head -n 2
echo
echo "Ready. Next: ./scripts/forward.sh"
