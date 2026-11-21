# Service Level Objectives: checkout

## SLO 1: Availability
- **SLI:** share of `GET /checkout` requests at the gateway that return a non-5xx status.
- **Objective:** 99% over a rolling 30 days.
- **Error budget:** 1% (about 130,000 failed requests at 5 req/s).
- **Why the gateway:** it is the user-facing edge. Failures anywhere below it surface here.

## Alerting (multi-window, multi-burn-rate)
Burn rate = error ratio / 0.01.

| Alert | Burn rate | Lab windows | Production windows | Budget consumed | Action |
|---|---|---|---|---|---|
| CheckoutErrorBudgetFastBurn | 14.4x | 10m and 2m | 1h and 5m | 2% in 1 hour | Page |
| CheckoutErrorBudgetSlowBurn | 6x | 30m and 5m | 6h and 30m | 5% in 6 hours | Ticket |

Both windows must exceed the threshold: the long window proves it is significant,
the short window makes the alert resolve quickly once the problem is fixed.

## Planned
- SLO 2: 95% of checkouts complete in under 500 ms (lab noise: p99 reaches about 250 ms).
