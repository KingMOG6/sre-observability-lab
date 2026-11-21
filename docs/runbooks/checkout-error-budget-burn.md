# Runbook: checkout error budget burn

**Alerts:** `CheckoutErrorBudgetFastBurn` (page), `CheckoutErrorBudgetSlowBurn` (ticket)
**Meaning:** the share of failing `/checkout` requests is burning the 30-day error budget faster than allowed. See `docs/slo.md`.

## 1. Confirm it is real
- Open Grafana → **Shop: Golden Signals** and check **Errors: checkout error ratio**.
- Make sure traffic is flowing. No traffic means no measurement, not "healthy":
  `sum(rate(http_requests_total{service="gateway",path="/checkout"}[1m]))`

## 2. Find the failing layer
Open **Errors by service and status**:

| Pattern | Meaning |
|---|---|
| `payments 500` | payments is failing on its own: the root cause |
| `orders 503` | orders cannot reach payments (down or timing out) |
| `orders 502` | payments answered with an error |
| `gateway 502/503` | usually collateral damage from orders |

The deepest `500` is the root cause. `502`/`503` above it are symptoms.

## 3. Look for a cause
```bash
kubectl get pods -n shop
kubectl rollout history deployment/<service> -n shop
kubectl describe pod -n shop -l app=<service> | tail -n 30
kubectl logs -n shop deploy/<service> --tail=50
```
Ask: did anything deploy or change recently? Are pods restarting?

## 4. Mitigate
- **Bad rollout:** `kubectl rollout undo deployment/<service> -n shop`
- **Wrong settings or injected fault:** reset everything to the state in Git:
  `kubectl apply -f k8s/shop/shop.yaml`
- **Crash-looping pod:** read `kubectl describe pod` first, then fix the cause. Do not just delete the pod.

## 5. Verify recovery
- `slo:checkout_error_ratio:rate2m` returns to about 0.
- Alerts resolve within about 10 minutes (the long window must drain).

## 6. Afterwards
Write a blameless postmortem in `docs/postmortems/` and record follow-up actions.
