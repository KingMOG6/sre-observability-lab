#!/usr/bin/env bash
# Sends ~5 checkout requests per second through the gateway. Ctrl+C to stop.
while true; do
  curl -s -o /dev/null localhost:8082/checkout
  sleep 0.2
done
