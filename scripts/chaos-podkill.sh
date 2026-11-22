#!/usr/bin/env bash
# Usage: scripts/chaos-podkill.sh <payments|orders> <replicas>
# Needs the gateway port-forward on localhost:8082 (scripts/forward.sh).
# Don't use it on "gateway": killing the pod behind the port-forward breaks the tunnel.
SVC=${1:-payments}; REPLICAS=${2:-1}
OUT=docs/chaos/podkill-${SVC}-${REPLICAS}-replica.md
mkdir -p docs/chaos
kubectl scale deployment "$SVC" -n shop --replicas="$REPLICAS" >/dev/null
kubectl rollout status deployment/"$SVC" -n shop --timeout=120s >/dev/null
sleep 5
START=$(date -u +%FT%TZ)
(
  sleep 5
  POD=$(kubectl get pods -n shop -l app="$SVC" --field-selector=status.phase=Running -o name | head -n1)
  kubectl delete -n shop "$POD" --wait=false >/dev/null
  echo "Killed $POD at $(date -u +%T)Z" > /tmp/kill.txt
) &
RESULTS=$(for i in $(seq 1 120); do curl -s -m 3 -o /dev/null -w "%{http_code}\n" localhost:8082/checkout; sleep 0.5; done | sort | uniq -c)
wait
END=$(date -u +%FT%TZ)
{
  echo "# Chaos: kill one $SVC pod ($REPLICAS replica(s))"
  echo
  echo "- Start: $START"
  echo "- End: $END"
  echo "- $(cat /tmp/kill.txt)"
  echo "- Probe: 120 requests to /checkout, one every 0.5 s"
  echo
  echo "Status code counts (000 means no response within 3 s):"
  echo
  echo '```text'
  echo "$RESULTS"
  echo '```'
} > "$OUT"
cat "$OUT"
