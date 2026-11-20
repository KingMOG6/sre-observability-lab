#!/usr/bin/env bash
# Run after a reboot: brings the lab back to a known state.
docker start sre-control-plane >/dev/null 2>&1 || true
kind export kubeconfig --name sre
kubectl config use-context kind-sre
echo "Waiting for the node..."
kubectl wait --for=condition=Ready node --all --timeout=180s
kubectl get pods -n shop
kubectl get pods -n monitoring
free -h | head -n 2
