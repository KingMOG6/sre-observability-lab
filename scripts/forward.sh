#!/usr/bin/env bash
# Opens gateway, Prometheus and Grafana on localhost. Ctrl+C stops all three.
kubectl port-forward -n shop svc/gateway 8082:8080 >/dev/null &
kubectl port-forward -n monitoring svc/prometheus-server 9090:80 >/dev/null &
kubectl port-forward -n monitoring svc/grafana 3000:80 >/dev/null &
echo "Gateway http://localhost:8082 | Prometheus http://localhost:9090 | Grafana http://localhost:3000"
trap 'kill 0' INT TERM
wait
