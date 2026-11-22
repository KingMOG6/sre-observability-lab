#!/usr/bin/env bash
# Usage: scripts/load-parallel.sh [workers]   (Ctrl+C stops all)
W=${1:-6}
trap 'kill 0' INT TERM
for i in $(seq 1 "$W"); do
  ( while true; do curl -s -m 5 -o /dev/null localhost:8082/checkout; sleep 0.3; done ) &
done
wait
