# Postmortem INC-001: Checkout error budget burn during SLO validation

**Date:** 2026-11-21 | **Severity:** low (lab, deliberate fault) | **Status:** resolved

## Summary
While validating the checkout SLO alerts, a 30% error rate was injected into `payments`
(`kubectl set env deployment/payments ERROR_RATE=0.3`). Checkout failures rose to about 30%,
both burn-rate alerts fired, and the fault stayed active longer than the test needed.

## Impact
- About 30% of `/checkout` requests failed (gateway 502) at roughly 3 requests per second.
- Burn rate was about 30x (error ratio 0.30 / error budget 0.01).
- Error budget consumed: about `<duration in minutes> x 30 / 43,200` of the 30-day budget.
  Fill in the duration (from first error to reset) and compute the percentage.

## Timeline (UTC)
| Time | Event |
|---|---|
| `<22:51>` | `ERROR_RATE=0.3` injected into payments |
| 21:50 | `CheckoutErrorBudgetFastBurn` and `CheckoutErrorBudgetSlowBurn` both active (from the Prometheus API) |
| `<23:02>` | Deployment env inspected: `ERROR_RATE` still `0.3`, error ratio 0.30 confirmed |
| `<23:05>` | `ERROR_RATE` reset to 0 |
| about 10 min later | Both alerts back to inactive (long window drained) |

## Root cause
The injected fault was left running after the test objective (seeing the alerts fire) was met.
Nothing in the process reverted it, and the manual reset step was easy to forget.

## Detection
Alerts fired as designed. The Errors by service and status panel showed `payments 500`
as the root cause and `orders 502` and `gateway 502` as downstream symptoms.

## What went well
- Multi-window burn-rate alerts fired on a sustained fault and cleared after it ended.
- The deepest-500 pattern pointed to payments immediately.
- The error ratio panel was fixed to show 0% instead of "No data" when there are no errors.

## What went badly
- The fault stayed on longer than intended and kept consuming error budget.
- Prometheus has no persistent storage, so a restart erased the metric history needed for this review.
- The error ratio panel originally showed "No data" instead of 0%, which hid the healthy state.

## Action items
| Action | Priority | Status |
|---|---|---|
| Add `scripts/fault.sh`, which injects a fault and auto-reverts after a set time | High | Done |
| Enable Prometheus persistence (or remote storage) so incident data survives restarts | Medium | Open |
| Record every experiment's start and end time in `docs/chaos/` | Medium | Done |

*Blameless: this document looks at systems and processes, not individuals.*
