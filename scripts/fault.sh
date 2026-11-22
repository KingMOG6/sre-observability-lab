#!/usr/bin/env bash
# Usage: scripts/fault.sh <service> <VAR=value> <minutes>
# Example: scripts/fault.sh payments ERROR_RATE=0.3 5
# Injects the fault, waits, then reverts. Ctrl+C reverts immediately.
SVC=${1:?service}; KV=${2:?VAR=value}; MIN=${3:-5}
VAR=${KV%%=*}
ORIG=$(kubectl get deploy "$SVC" -n shop -o jsonpath="{.spec.template.spec.containers[0].env[?(@.name=='$VAR')].value}")
trap 'kubectl set env deployment/"$SVC" -n shop "$VAR=$ORIG" >/dev/null; echo "Reverted $SVC $VAR=$ORIG at $(date -u +%T)Z"' EXIT
kubectl set env deployment/"$SVC" -n shop "$KV" >/dev/null
echo "Injected $KV on $SVC at $(date -u +%T)Z. Auto-revert to $VAR=$ORIG in ${MIN}m (Ctrl+C reverts now)."
sleep $((MIN * 60))
